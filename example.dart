import 'automaton.dart';

int main() {
  CommandLineAutomaton am = new CommandLineAutomaton();
  TokenList tokens = am.run('ls -la *.c | cat -e > out.txt && cat out.txt');
  print(tokens);
  return 0;
}

class StringAutomaton extends Automaton {
  int finalState = 1;

  void lex() {
    findRegExp(0, 1, new RegExp(r'^([a-zA-Z-.*]+)'));
  }
}

class CommandLineAutomaton extends Automaton {
  int finalState = 2;

  void lex() {
    findWhitespace(0, 1);
    findEnd(0, 2);
    findStrings(0, 1, ['||', '&&', ';', '|', '&', '>>', '<<', '>', '<']);
    findAutomaton(0, 1, () => new StringAutomaton());
    findAutomaton(1, 2, () => new CommandLineAutomaton());
    findEnd(1, 2);
  }
}