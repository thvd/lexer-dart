/**
 * Automaton generation tools
 *
 * Check Github for sources of pull requests:
 * [Github Repo](https://github.com/conradkleinespel/automaton-generator-dart)
 *
 * This library is distributed under the MIT license. Review it here:
 * [MIT license](http://conradk.mit-license.org/license.html)
 */
library automaton;

import 'dart:collection';

/**
 * An base automaton used to generate more complex ones
 *
 * Example:
 *
 *     class QuotedStringAutomaton extends Automaton {
 *         int finalState = 3;
 *
 *         void lex() {
 *             findString(0, 1, '"');
 *             findRegExp(1, 2, new RegExp(r'^([^"]+)'));
 *             findString(2, 3, '"');
 *         }
 *     }
 *
 *     List<String> tokens = new QuotedStringAutomaton().run('"Hello world!"');
 */
abstract class Automaton {
  TokenList tokens;
  String source;
  int _currentState;
  int finalState = 0;
  int initialState = 0;

  void _init(String str) {
    _currentState = initialState;
    source = str;
    tokens = new TokenList();
  }

  void lex();

  int get currentState => _currentState;

  TokenList run(String str, {bool joinTokens: false}) {
    _init(str);
    lex();
    TokenList finalTokens = (_currentState == finalState) ? tokens : null;
    if (joinTokens && finalTokens != null) {
      String value = finalTokens.join();
      String originalValue = finalTokens.joinOriginals();
      finalTokens.clear();
      finalTokens.add(new Token(value, originalValue: originalValue));
    }
    return finalTokens;
  }

  int get length {
    int len = 0;
    for (int i = 0; i < tokens.length; i++)
      len += tokens[i].originalLength;
    return len;
  }

  void addToken(Token tok) {
    tokens.add(tok);
    source = source.substring(tok.originalLength);
  }

  bool _isSpace(String str) {
    return [' ', '\t', '\r', '\n', '\v'].contains(str);
  }

  void _find(int from, int to, bool func()) {
    if (from != _currentState)
      return ;
    if (func())
      _currentState = to;
  }

  void findWhitespace(int from, int to) {
    _find(from, to, () {
      int numSpaces = 0;
      if (source.length > 0 && _isSpace(source[0])) {
        for (int i = 0; i < source.length; i++) {
          if (_isSpace(source[i]))
            numSpaces++;
          else
            break;
        }
        if (numSpaces > 0) {
          String str = source.substring(0, numSpaces);
          addToken(new Token(str));
          return true;
        }
      }
      return false;
    });
  }

  void findString(int from, int to, String str) {
    _find(from, to, () {
      if (source.length >= str.length && source.substring(0, str.length) == str) {
        addToken(new Token(str));
        return true;
      }
      return false;
    });
  }

  void findStrings(int from, int to, List<String> str) {
    _find(from, to, () {
      for (int i = 0; i < str.length; i++) {
        if (source.length >= str[i].length && source.substring(0, str[i].length) == str[i]) {
          addToken(new Token(str[i]));
          return true;
        }
      }
      return false;
    });
  }

  void findAutomaton(int from, int to, Function amMaker, {bool joinTokens: false}) {
    _find(from, to, () {
      TokenList subtokens = amMaker().run(source, joinTokens: joinTokens);
      if (subtokens != null) {
        tokens.addAll(subtokens);
        source = source.substring(subtokens.originalTokenLength);
        return true;
      }
      return false;
    });

  }

  void findRegExp(int from, int to, RegExp check) {
    _find(from, to, () {
      RegExp regexp = check;
      String tok;
      if ((tok = regexp.stringMatch(source)) != null) {
        String str = source.substring(0, tok.length);
        addToken(new Token(str));
        return true;
      }
      return false;
    });
  }

  void findEnd(int from, int to) {
    _find(from, to, () {
      return source.length == 0;
    });
  }

  void findCallback(int from, int to, bool getToken()) {
    _find(from, to, () {
      return getToken();
    });
  }
}

class TokenList<E> extends ListBase<E> {
  List<Token> innerList = new List<Token>();

  int get length => innerList.length;

  void set length(int num) {
    innerList.length = num;
  }

  int get originalTokenLength => this.joinOriginals().length;

  int get tokenLength => this.join().length;

  void add(Token el) {
    innerList.add(el);
  }

  void operator[]=(int index, Token value) {
    innerList[index] = value;
  }

  Token operator [](int index) => innerList[index];

  bool get isEmpty => innerList.isEmpty;

  String join([String separator = ""]) => innerList.join(separator);

  String joinOriginals([String separator]) {
    String out = '';
    for (int i = 0; i < innerList.length; i++) {
      if (i != 0 && separator != null)
        out += separator;
      out += innerList[i].originalValue;
    }
    return out;
  }

  void clear() {
    innerList.clear();
  }
}

class Token {
  String value;
  String originalValue;

  int get originalLength => originalValue.length;

  int get length => value.length;

  Token(String value, {String originalValue}) {
    this.value = value;
    this.originalValue = (originalValue != null) ? originalValue : value;
  }

  String toString() => value;
}