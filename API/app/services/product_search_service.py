import re
from urllib.parse import quote_plus

import httpx

from app.config import settings


def _google_search_url(reference: str) -> str:
    query = quote_plus(f"{reference} produit fiche technique prix")
    return f"https://www.google.com/search?q={query}"


def _google_shopping_url(reference: str) -> str:
    query = quote_plus(reference)
    return f"https://www.google.com/search?tbm=shop&q={query}"


def _parse_price_value(text: str | None) -> float | None:
    if not text:
        return None
    cleaned = text.replace("\u202f", " ").replace("\xa0", " ")
    cleaned = re.sub(r"[^\d,.\s]", "", cleaned).strip()
    if not cleaned:
        return None
    # Format européen : 3 600,00
    if "," in cleaned and "." not in cleaned:
        cleaned = cleaned.replace(" ", "").replace(",", ".")
    elif " " in cleaned and "," not in cleaned:
        cleaned = cleaned.replace(" ", "")
    try:
        value = float(cleaned)
        return value if value > 0 else None
    except ValueError:
        return None


def _add_unique(results: list[dict], seen: set[str], item: dict) -> None:
    url = (item.get("url") or "").strip()
    key = url or f"{item.get('title', '')}|{item.get('merchant', '')}"
    if key in seen:
        return
    seen.add(key)
    results.append(item)


def _search_serpapi(reference: str, max_results: int, seen: set[str]) -> list[dict]:
    results: list[dict] = []
    if not settings.serp_api_key:
        return results

    queries = [
        ("google_shopping", reference, "shopping_results"),
        ("google", f"{reference} produit prix fiche technique", "organic_results"),
    ]

    for engine, query, result_key in queries:
        if len(results) >= max_results:
            break
        try:
            response = httpx.get(
                "https://serpapi.com/search",
                params={
                    "engine": engine,
                    "q": query,
                    "api_key": settings.serp_api_key,
                    "num": max_results,
                    "gl": "ci",
                    "hl": "fr",
                },
                timeout=20,
            )
            if response.status_code != 200:
                continue
            payload = response.json()
            for item in payload.get(result_key, [])[:max_results]:
                title = item.get("title", "")
                url = item.get("link") or item.get("product_link") or ""
                snippet = item.get("snippet") or item.get("description") or ""
                price_label = item.get("price") or item.get("extracted_price") or ""
                if isinstance(price_label, (int, float)):
                    price_value = float(price_label)
                    price_label = f"{price_value:,.0f} FCFA".replace(",", " ")
                else:
                    price_value = item.get("extracted_price")
                    if price_value is None:
                        price_value = _parse_price_value(str(price_label))
                    elif isinstance(price_value, str):
                        price_value = _parse_price_value(price_value)
                merchant = item.get("source") or item.get("seller") or ""
                image_url = item.get("thumbnail") or item.get("image") or ""
                _add_unique(
                    results,
                    seen,
                    {
                        "title": title,
                        "url": url,
                        "snippet": snippet,
                        "price": price_value,
                        "price_label": str(price_label) if price_label else "",
                        "merchant": merchant,
                        "image_url": image_url,
                        "source": "serpapi_shopping" if engine == "google_shopping" else "serpapi",
                    },
                )
        except Exception:
            continue
    return results


def _search_brave(reference: str, max_results: int, seen: set[str]) -> list[dict]:
    results: list[dict] = []
    if not settings.brave_api_key:
        return results
    try:
        response = httpx.get(
            "https://api.search.brave.com/res/v1/web/search",
            params={"q": f"{reference} produit prix", "count": max_results},
            headers={
                "Accept": "application/json",
                "X-Subscription-Token": settings.brave_api_key,
            },
            timeout=15,
        )
        if response.status_code != 200:
            return results
        for item in response.json().get("web", {}).get("results", [])[:max_results]:
            title = item.get("title", "")
            url = item.get("url", "")
            snippet = item.get("description", "")
            price_value = _parse_price_value(snippet) or _parse_price_value(title)
            _add_unique(
                results,
                seen,
                {
                    "title": title,
                    "url": url,
                    "snippet": snippet,
                    "price": price_value,
                    "price_label": f"{price_value:,.0f} FCFA".replace(",", " ") if price_value else "",
                    "merchant": "",
                    "image_url": "",
                    "source": "brave",
                },
            )
    except Exception:
        pass
    return results


def _search_duckduckgo(reference: str, max_results: int, seen: set[str]) -> list[dict]:
    results: list[dict] = []
    ddgs_cls = None
    try:
        from ddgs import DDGS as DDGSNew
        ddgs_cls = DDGSNew
    except ImportError:
        try:
            from duckduckgo_search import DDGS as DDGSOld
            ddgs_cls = DDGSOld
        except ImportError:
            return results

    try:
        with ddgs_cls() as ddgs:
            queries = [
                f"{reference} product datasheet price site:siemens.com OR site:schneider-electric.com OR site:abb.com",
                f"{reference} produit prix fiche technique",
            ]
            for query in queries:
                if len(results) >= max_results:
                    break
                for item in ddgs.text(query, max_results=max_results):
                    snippet = item.get("body", "")
                    title = item.get("title", "")
                    price_value = _parse_price_value(snippet) or _parse_price_value(title)
                    _add_unique(
                        results,
                        seen,
                        {
                            "title": title,
                            "url": item.get("href", ""),
                            "snippet": snippet,
                            "price": price_value,
                            "price_label": f"{price_value:,.0f} FCFA".replace(",", " ") if price_value else "",
                            "merchant": "",
                            "image_url": "",
                            "source": "duckduckgo",
                        },
                    )
    except Exception:
        pass
    return results


def search_product_reference(reference: str, max_results: int = 10) -> dict:
    reference = reference.strip().upper()
    seen: set[str] = set()
    results: list[dict] = []

    # SerpApi en priorité (Google Shopping + Google Search)
    results.extend(_search_serpapi(reference, max_results, seen))

    # Compléter avec Brave si configuré
    if len(results) < max_results:
        results.extend(_search_brave(reference, max_results - len(results), seen))

    # Fallback DuckDuckGo si peu ou pas de résultats
    if len(results) < 3:
        results.extend(_search_duckduckgo(reference, max_results, seen))

    suggested = ""
    if results:
        first = results[0]
        suggested = first.get("snippet") or first.get("title") or ""

    return {
        "reference": reference,
        "results": results[:max_results],
        "search_url": _google_search_url(reference),
        "shopping_url": _google_shopping_url(reference),
        "suggested_designation": suggested[:500] if suggested else "",
    }
