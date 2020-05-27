package scanner;
import "core:fmt";
import "core:os";

Token :: enum {
  NULL,
  TIMES,
  DIV,
  MOD,
  AND,
  PLUS,
  MINUS,
  OR,
  EQL,
  NEQ,
  LSS,
  GEQ,
  LEQ,
  GTR,
  PERIOD,
  COMMA,
  COLON,
  RPAREN,
  RBRAK,
  OF,
  THEN,
  DO,
  LPAREN,
  LBRAK,
  NOT,
  BECOMES,
  NUMBER,
  IDENT,
  SEMICOLON,
  END,
  ELSE,
  ELSIF,
  IF,
  WHILE,
  ARRAY,
  RECORD,
  CONST,
  TYPE,
  VAR,
  PROCEDURE,
  BEGIN,
  MODULE,
  EOF
}

@static
key_table := map[string]Token {
  "BY" = .NULL,
  "DO" = .DO,
  "IF" = .IF,
  "OF" = .OF,
  "END" = .END,
  "MOD" = .MOD,
  "VAR" = .VAR,
  "ELSE" = .ELSE,
  "THEN" = .THEN,
  "TYPE" = .TYPE,
  "ARRAY" = .ARRAY,
  "BEGIN" = .BEGIN,
  "CONST" = .CONST,
  "ELSIF" = .ELSIF,
  "WHILE" = .WHILE,
  "RECORD" = .RECORD,
  "PROCEDURE" = .PROCEDURE,
  "DIV" = .DIV,
  "MODULE" = .MODULE
};


//global scanner state
IdLen :: 16;
Ident :: distinct [IdLen]byte;
val: int;
id: Ident;
error: bool;
errpos: int;
index: int;
line: int;
col: int;
source: string;
sym: Token;


//TODO(josh): track actual line/column positions when lexing for error reporting
mark :: proc(msg: string) {
  if index > errpos {
    fmt.printf("ERROR! (%d, %d) %s\n", line, col, msg);
    errpos := index;
    error := true;
  }
}



advance :: proc() {
  index += 1;
  col += 1;

  if source[index] == '\r' && source[index + 1] == '\n' { //TODO(josh): generalize this, add tabs, etc
    index += 2;
    col = 0;
    line += 1;
  } else if source[index] == '\n' {
    index += 1;
    col = 0;
    line += 1;
  }
}




get :: proc() {


  ident :: proc() {
    is_alnum :: proc(char: byte) -> bool {
      return (char >= 'a' && char <= 'z') ||
            (char >= 'A' && char <= 'Z') ||
            (char >= '0' && char <= '9');
    };

    start_index := index;
    for is_alnum(source[index]) do index += 1;
    ident := source[start_index:index];
    t, ok := key_table[ident];
    
    if(ok) {
      sym = t;
    } else {
      sym = .IDENT;
    }
  }


  number :: proc () {
    val = 0;
    sym = .NUMBER;

    //TODO(josh): check for number that's too large
    for source[index] >= '0' && source[index] <= '9' {
      if val <= (0xffffffff + int('0' - source[index])) / 10 {
        val *= val;
        val += int(source[index] - '0');
        advance();
      } else {
        mark("number too large");
        val = 0;
      }
    }
  }

  comment :: proc () {
    index += 1;
    for {
      for {
        for source[index] == '(' {
          advance();
          if source[index] == '*' {
            comment();
          }
        }
        if source[index] == '*' {
          advance();
          break;
        }
        if source[index] == 0 {
          break;
        }
        advance();
      }
      if source[index] == ')' {
        advance();
        break;
      }
      if source[index] == 0 {
        mark("comment not terminated");
        break;
      }
    }
  }
  

  //skip whitespace
  for source[index] <= ' ' && source[index] != 0 do index += 1;
  if source[index] == 0 {
    sym = .EOF;
  } else {
    switch source[index] {
      case 'a'..'z', 'A'..'Z':
        ident();
      case '0'..'9':
        number();
      case '&': 
        advance();
        sym = .AND;
      case '*':
        advance();
        sym = .TIMES;
      case '+':
        advance();
        sym = .PLUS;
      case '-':
        advance();
        sym = .MINUS;
      case '=':
        advance();
        sym = .EQL;
      case '#':
        advance();
        sym = .NEQ;
      case '<':
        advance();
        if index == '=' {
          advance();
          sym = .LEQ; 
        } else {
          sym = .LSS;
        }
      case '>':
        advance();
        if index == '=' {
          advance();
          sym = .GEQ; 
        } else {
          sym = .GTR;
        }
      case ';':
        advance();
        sym = .SEMICOLON;
      case '.':
        advance();
        sym = .PERIOD;
      case ',':
        advance();
        sym = .COMMA;
      case ':':
        advance();
        if source[index] == '=' {
          advance();
          sym = .BECOMES; 
        } else {
          sym = .COLON;
        }
      case '(':
        advance();
        if source[index] == '*' {
          comment();
          get();
        } else {
          sym = .LPAREN;
        }
      case ')':
        advance();
        sym = .RPAREN;
      case '[':
        advance();
        sym = .LBRAK;
      case ']':
        advance();
        sym = .RBRAK;
      case '~':
        advance();
        sym = .NOT;
      case:
        advance();
        sym = .NULL;
    }
  }
  // fmt.print("GET: ");
  // fmt.println(sym);
}

init :: proc(s: string) {
  source = s;
  error  = false;
  index  = 0;
  line   = 1;
  col    = 0;
  errpos = 0;
};