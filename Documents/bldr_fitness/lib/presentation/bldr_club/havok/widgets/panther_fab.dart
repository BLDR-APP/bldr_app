import 'package:flutter/material.dart';
import '../havok_hub.dart'; // Importa a tela do Hub que criamos

// TODO: Se você tiver uma tela de vendas, importe-a aqui.
// import 'caminho/para/premium_upsell_screen.dart';

class PantherFab extends StatelessWidget {
  const PantherFab({super.key});

  @override
  Widget build(BuildContext context) {
    // =======================================================================
    // LÓGICA DE ESTADO (Premium vs. Não-Premium)
    // !! IMPORTANTE !!: Substitua esta variável pela sua lógica real
    // para verificar se o usuário é assinante premium.
    // =======================================================================
    final bool isPremiumUser = true; // Mude para 'false' para testar o cadeado

    return GestureDetector( // Usamos GestureDetector para detectar o toque
      onTap: () {
        if (isPremiumUser) {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const HavokHubScreen()),
          );
        } else {
          print("Navegando para a tela de Upsell Premium...");
          // Navigator.push(context, MaterialPageRoute(builder: (context) => const PremiumUpsellScreen()));
        }
      },
      child: Container( // Usamos um Container para aplicar a sombra e o tamanho
        width: 70.0,
        height: 70.0,
        decoration: BoxDecoration(
          // REMOVEMOS O BACKGROUND AQUI
          // borderRadius: BorderRadius.circular(16.0), // Se quiser borda, pode manter
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.6), // Cor da sombra
              blurRadius: 10, // Intensidade do blur
              spreadRadius: 2, // Espalhamento da sombra
              offset: const Offset(0, 4), // Posição da sombra (x, y)
            ),
          ],
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            // A imagem da pantera
            Image.asset(
              'assets/images/havok.png',
              width: 70, // Ajustamos a largura para preencher o Container
              height: 70, // Ajustamos a altura para preencher o Container
              fit: BoxFit.contain, // Garante que a imagem se ajuste
            ),

            // O cadeado (só aparece se o usuário NÃO for premium)
            if (!isPremiumUser)
              Positioned(
                right: 4,
                bottom: 4,
                child: Icon(
                  Icons.lock,
                  color: Colors.amber.withOpacity(0.8),
                  size: 18,
                ),
              ),
          ],
        ),
      ),
    );
  }
}