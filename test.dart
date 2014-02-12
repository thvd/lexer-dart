import 'lib/lexer.dart';
import 'package:unittest/unittest.dart';

void main() {
  test('Token#value', () {
    Token token = new Token('that');
    expect(token.value, equals('that'));
    expect(token.originalValue, equals('that'));
    token = new Token('that', originalValue: 'but not that');
    expect(token.value, equals('that'));
    expect(token.originalValue, equals('but not that'));
  });

  test('Token#originalValue', () {
    // tested above
  });

  test('Token#length', () {
    Token token = new Token('that', originalValue: 'other');
    expect(token.length, equals(4));
    expect(token.originalLength, equals(5));
  });

  test('Token#originalLength', () {
    // tested above
  });

  test('Automaton#findWhitespace', () {
    CommandLineAutomaton am = new CommandLineAutomaton();
    TokenList tokens = am.run('cat\t  \n -e');
    expect(tokens[1].originalValue, equals('\t  \n '));
    expect(tokens[1].value, equals('\t  \n '));
  });

  test('Automaton#findString', () {
    CommandLineAutomaton am = new CommandLineAutomaton();
    TokenList tokens = am.run("'hello'");
    expect(tokens[0].originalValue, equals("'"));
    expect(tokens[0].value, equals("'"));
    expect(tokens[2].originalValue, equals("'"));
    expect(tokens[2].value, equals("'"));
  });

  test('Automaton#findCallback', () {
    CommandLineAutomaton am = new CommandLineAutomaton();
    TokenList tokens = am.run('cat\t  \n -e');
    expect(tokens[0].originalValue, equals('cat'));
    expect(tokens[0].value, equals('cat'));
    expect(tokens[2].originalValue, equals('-e'));
    expect(tokens[2].value, equals('-e'));
  });

  test('Automaton#findStrings', () {
    CommandLineAutomaton am = new CommandLineAutomaton();
    TokenList tokens = am.run('cat |wc;ls|| ps -e');
    expect(tokens[0].originalValue, equals('cat'));
    expect(tokens[0].value, equals('cat'));
    expect(tokens[1].originalValue, equals(' '));
    expect(tokens[1].value, equals(' '));
    expect(tokens[2].originalValue, equals('|'));
    expect(tokens[2].value, equals('|'));
    expect(tokens[3].originalValue, equals('wc'));
    expect(tokens[3].value, equals('wc'));
    expect(tokens[4].originalValue, equals(';'));
    expect(tokens[4].value, equals(';'));
    expect(tokens[5].originalValue, equals('ls'));
    expect(tokens[5].value, equals('ls'));
    expect(tokens[6].originalValue, equals('||'));
    expect(tokens[6].value, equals('||'));
    expect(tokens[7].originalValue, equals(' '));
    expect(tokens[7].value, equals(' '));
  });

  test('Automaton#findAutomaton with joinTokens = true', () {
    CommandLineAutomaton am = new CommandLineAutomaton();
    TokenList tokens = am.run('cat');
    expect(tokens[0].value, equals('cat'));
  });

  test('Automaton#findAutomaton with joinTokens = false', () {
    CommandLineAutomaton am = new CommandLineAutomaton();
    TokenList tokens = am.run(r'"hello\" that\" \r stuffworld"');
    expect(tokens[0].value, equals('"'));
    expect(tokens[0].originalValue, equals('"'));
    expect(tokens[1].value, equals('hello" that" r stuffworld'));
    expect(tokens[1].originalValue, equals(r'hello\" that\" \r stuffworld'));
    expect(tokens[2].value, equals('"'));
    expect(tokens[2].originalValue, equals('"'));
  });

  test('TokenList#tokenLength', () {
    CommandLineAutomaton am = new CommandLineAutomaton();
    TokenList tokens = am.run(r'"hello\" that\" \r stuffworld"');
    expect(tokens.tokenLength, equals(27));
  });

  test('TokenList#originalTokenLength', () {
    CommandLineAutomaton am = new CommandLineAutomaton();
    TokenList tokens = am.run(r'"hello\" that\" \r stuffworld"');
    expect(tokens.originalTokenLength, equals(30));
  });
}

class DoubleQuotedStringContentAutomaton extends Automaton {
  int finalState = 1;

  void lex() {
    findCallback(0, 0, () {
      if (source.length > 1 && source[0] == r'\') {
        addToken(new Token(source[1], originalValue: source.substring(0, 2)));
        return true;
      }
      if (source.length > 0 && source[0] != '"') {
        addToken(new Token(source[0]));
        return true;
      }
      return false;
    });
    findCallback(0, 1, () => source.length > 0 && source[0] == '"');
    findAutomaton(0, 1, () => new DoubleQuotedStringContentAutomaton());
  }
}

class DoubleQuotedStringAutomaton extends Automaton {
  int finalState = 3;

  void lex() {
    findString(0, 1, '"');
    findAutomaton(1, 2, () => new DoubleQuotedStringContentAutomaton(), joinTokens: true);
    findString(2, 3, '"');
  }
}

class SingleQuotedStringContentAutomaton extends Automaton {
  int finalState = 1;

  void lex() {
    findCallback(0, 0, () {
      if (source.length > 0 && source[0] != "'") {
        addToken(new Token(source[0]));
        return true;
      }
      return false;
    });
    findCallback(0, 1, () => source.length > 0 && source[0] == "'");
    findAutomaton(0, 1, () => new SingleQuotedStringContentAutomaton());
  }
}

class SingleQuotedStringAutomaton extends Automaton {
  int finalState = 3;

  void lex() {
    findString(0, 1, "'");
    findAutomaton(1, 2, () => new SingleQuotedStringContentAutomaton(), joinTokens: true);
    findString(2, 3, "'");
  }
}

class UnquotedStringContentAutomaton extends Automaton {
  int finalState = 2;

  List<String> separators = ['>', '<', '|', '&', ';', '"', "'", ' ', '\t', '\r', '\n', '\v'];

  void lex() {
    findCallback(0, 1, () {
      if (source.length > 1 && source[0] == r'\') {
        addToken(new Token(source[1], originalValue: source[0] + source[1]));
        return true;
      }
      if (source.length > 0 && !separators.contains(source[0])) {
        addToken(new Token(source[0]));
        return true;
      }
      return false;
    });
    findCallback(1, 2, () => source.length == 0 || separators.contains(source[0]));
    findAutomaton(1, 2, () => new UnquotedStringContentAutomaton());
  }
}

class UnquotedStringAutomaton extends Automaton {
  int finalState = 1;

  void lex() {
    findAutomaton(0, 1, () => new UnquotedStringContentAutomaton(), joinTokens: true);
  }
}

class CommandLineAutomaton extends Automaton {
  int finalState = 2;

  void lex() {
    findWhitespace(0, 1);
    findEnd(0, 2);
    findRegExp(0, 1, new RegExp(r'^(<<|>>)'));
    findStrings(0, 1, [';', '||', '|', '&&', '&', '>>', '<<', '>', '<']);
    findAutomaton(0, 1, () => new DoubleQuotedStringAutomaton(), joinTokens: false);
    findAutomaton(0, 1, () => new SingleQuotedStringAutomaton());
    findAutomaton(0, 1, () => new UnquotedStringAutomaton());
    findAutomaton(1, 2, () => new CommandLineAutomaton());
    findEnd(1, 2);
  }
}