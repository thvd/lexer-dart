# Automaton based lexer helper for Dart

Tools that make writing automaton based lexer's easy and enjoyable.

The code is released under the terms of the [MIT license](http://conradk.mit-license.org/license.html).

Please report bugs and submit pull requests with fixes and/or test cases.

[![Build Status](https://drone.io/github.com/conradkleinespel/automaton-generator-dart/status.png)](https://drone.io/github.com/conradkleinespel/automaton-generator-dart/latest)

## An example: simple Shell lexer

If you run `dart -c example.dart`, you should see the following output, representing the list of tokens found in the command line `ls -la *.c | cat -e > out.txt && cat out.txt`:
```
[ls,  , -la,  , *.c,  , |,  , cat,  , -e,  , >,  , out.txt,  , &&,  , cat,  , out.txt]
```

The code:
```dart
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
```