# Nomad
# Controle de Motor BLDC com Arduino e Potenciômetro

Este projeto utiliza um **Arduino** para controlar a velocidade de um **motor BLDC (Brushless DC)** através de um **ESC (Electronic Speed Controller)**.  
O controle é feito com um **potenciômetro de 1kΩ**, que ajusta a largura do pulso PWM enviado ao ESC.  

O objetivo principal é realizar **testes de velocidade do motor**, onde sensores de efeito Hall serão utilizados para leitura da rotação (RPM) em experimentos futuros.  

---

## 🔧 Componentes Utilizados
- Arduino (UNO, Mega ou equivalente)
- Motor BLDC (3 fases)
- ESC compatível com o motor
- Potenciômetro de 1kΩ
- Fonte de alimentação adequada para o motor + ESC
- Sensores de efeito Hall (para etapas futuras)
- Jumpers / Protoboard

---

## ⚡ Funcionamento
1. O potenciômetro é lido pelo **pino analógico A0** do Arduino.
2. O valor lido (0–1023) é **mapeado** para um intervalo de pulsos de **1000 µs a 2000 µs**, que são entendidos pelo ESC.
3. O ESC interpreta esse pulso e ajusta a velocidade do motor BLDC.
4. Futuramente, sensores de efeito Hall serão adicionados para medir a **velocidade real do motor (RPM)**, possibilitando controle em malha fechada.

---

## 📜 Código Atual

```cpp
#include <Servo.h>

Servo ESC;
int Speed;  

void setup() {
  ESC.attach(9, 1000, 2000); // Pino 9, pulso mínimo e máximo do ESC
}

void loop() {
  Speed = analogRead(A0); // Lê potenciômetro (0–1023)
  
  // Mapeia o valor do potenciômetro para o intervalo de pulso do ESC
  int escSignal = map(Speed, 0, 1023, 1000, 2000);

  ESC.writeMicroseconds(escSignal); // Envia sinal para o ESC
  delay(20); // Estabilização
}

