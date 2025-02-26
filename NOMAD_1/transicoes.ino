// Simulação de três sensores Hall
const int hall1Pin = 2;  // Sensor Hall 1
const int hall2Pin = 3;  // Sensor Hall 2
const int hall3Pin = 4;  // Sensor Hall 3

// Temporização para simular transições
unsigned long lastTransitionTime = 0;
const unsigned long transitionInterval = 100;  // Intervalo de 100ms para transições

// Estados possíveis para o motor BLDC com defasagem de 120 graus
const byte hallStates[12][3] = {
  {1, 0, 1},  // Estado 1
  {1, 0, 0},  // Estado 2
  {1, 1, 0},  // Estado 3
  {0, 1, 0},  // Estado 4
  {0, 1, 1},  // Estado 5
  {0, 0, 1},  // Estado 6
  {1, 0, 1},  // Estado 7 (repetição do estado 1 para o segundo par de polos)
  {1, 0, 0},  // Estado 8
  {1, 1, 0},  // Estado 9
  {0, 1, 0},  // Estado 10
  {0, 1, 1},  // Estado 11
  {0, 0, 1}   // Estado 12
};

int currentStateIndex = 0;  // Estado inicial

void setup() {
  // Inicialização dos pinos dos sensores Hall
  pinMode(hall1Pin, OUTPUT);
  pinMode(hall2Pin, OUTPUT);
  pinMode(hall3Pin, OUTPUT);
  
  // Inicializa o monitor serial para observar os resultados
  Serial.begin(9600);
}

void loop() {
  unsigned long currentTime = millis();

  // Simular transição para o próximo estado após o intervalo definido
  if (currentTime - lastTransitionTime >= transitionInterval) {
    // Atualizar o estado dos sensores Hall
    digitalWrite(hall1Pin, hallStates[currentStateIndex][0]);
    digitalWrite(hall2Pin, hallStates[currentStateIndex][1]);
    digitalWrite(hall3Pin, hallStates[currentStateIndex][2]);

    // Exibir o estado atual no monitor serial
    Serial.print("Estado Hall: ");
    Serial.print(hallStates[currentStateIndex][0]);
    Serial.print(hallStates[currentStateIndex][1]);
    Serial.println(hallStates[currentStateIndex][2]);

    // Avançar para o próximo estado
    currentStateIndex = (currentStateIndex + 1) % 12;
    lastTransitionTime = currentTime;
  }
}
