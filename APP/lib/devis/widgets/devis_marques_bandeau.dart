import 'package:flutter/material.dart';



/// Bandeau logos partenaires ISITEK (image assets).

class DevisMarquesBandeau extends StatelessWidget {

  const DevisMarquesBandeau({super.key});



  @override

  Widget build(BuildContext context) {

    return Image.asset(

      'assets/images/marques_partenaires.png',

      width: double.infinity,

      fit: BoxFit.contain,

      errorBuilder: (_, __, ___) => const SizedBox.shrink(),

    );

  }

}

