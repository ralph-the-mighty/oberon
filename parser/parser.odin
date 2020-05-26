package parser;
import "../scanner";
import "core:fmt";

WordSize :: 4;
loaded: bool;

// topScope: OSG.Object;
// universe: OSG.Object; /* linked lists, end with guards */
// guard: OSG.Object;





selector :: proc() {
  for scanner.sym == .LBRAK || scanner.sym == .PERIOD {
    if scanner.sym == .LBRAK {
      scanner.get();
      expression();
      if scanner.sym == .RBRAK {
        scanner.get();
      } else {
        scanner.mark("]?");
      }
    } else {
      //if not LBRAK, must be PERIOD
      scanner.get();
      if scanner.sym == .IDENT {
        scanner.get();
      } else {
        scanner.mark("ident?");
      }
    }
  }
}



factor :: proc() {
  //sync
  if scanner.sym == .IDENT {
    scanner.get();
  } else if scanner.sym == .NUMBER {
    scanner.get();
  } else if scanner.sym == .LPAREN {
    scanner.get();
    expression();
  } else if scanner.sym == .NOT {
    scanner.get();
    factor();
  } else {
    scanner.mark("factor?");
  }
}


term :: proc() {
  factor();
  for scanner.sym >= .TIMES && scanner.sym <= .AND {
    scanner.get();
    factor();
  }
}


simple_expression :: proc() {
  if scanner.sym == .PLUS || scanner.sym == .MINUS {
    scanner.get();
  }
  term();
  for scanner.sym >= .PLUS && scanner.sym <= .OR {
    scanner.get();
    term();
  }
}

expression :: proc() {
  simple_expression();
  if scanner.sym >= .EQL && scanner.sym <= .GTR {
    scanner.get();
    simple_expression();
  }
}


statement :: proc() {
  if scanner.sym == .IF {
    // if statements
    scanner.get();
    expression();
    if scanner.sym == .THEN {
      scanner.get();
    } else {
      scanner.mark("THEN?");
    }
    statement_sequence();
    for scanner.sym == .ELSIF {
      scanner.get();
      expression();
      if scanner.sym == .THEN {
        scanner.get();
      } else {
        scanner.mark("THEN?");
      }
      statement_sequence();
    }
    if scanner.sym == .ELSE {
      scanner.get();
      statement_sequence();
    }
    if scanner.sym == .END {
      scanner.get();
    } else {
      scanner.mark("END?");
    }
  } else if scanner.sym == .WHILE {
    //while statements
    scanner.get();
    expression();
    if scanner.sym == .DO {
      scanner.get();
    } else {
      scanner.mark("DO?");
    }
    statement_sequence();
    if scanner.sym == .END {
      scanner.get();
    } else {
      scanner.mark("END?");
    }
  } else if scanner.sym == .IDENT {
    // TODO(josh): implement procedure calls. Since we don't have
    // a symbol table right now, we're just assuming that the 
    // identifier always signifies an assignment
    scanner.get();
    selector();
    if scanner.sym == .BECOMES {
      scanner.get();
    } else {
      scanner.mark(":=?");
    }
    expression();
  }
  if scanner.sym == .SEMICOLON {
    scanner.get();
  } else {
    scanner.mark(";?");
  }
}

statement_sequence :: proc () {
  //sync
  for {
    if scanner.sym < .IDENT {
      scanner.mark("ident?");
      for scanner.sym < .IDENT do scanner.get();
    }
    statement();
    if scanner.sym == .SEMICOLON {
      scanner.get();
    } else if (scanner.sym >= .SEMICOLON && scanner.sym < .IF) || 
              scanner.sym  >= .ARRAY {
      break;
    } else {
      scanner.mark("semicolon?");
    }
  }
}







declarations :: proc () {

}


module :: proc() {
  modid : scanner.Ident;
  if scanner.sym == .MODULE {
    scanner.get();
    if scanner.sym == .IDENT {
      scanner.get();
    } else {
      scanner.mark("ident?");
    }

    if scanner.sym == .SEMICOLON {
      scanner.get();
    } else {
      scanner.mark("semicolon?");
    }

    declarations();

    if scanner.sym == .BEGIN {
      scanner.get();
      statement_sequence();
    }

    if scanner.sym == .END {
      scanner.get();
    } else {
      scanner.mark("END?");
    }

    if scanner.sym == .IDENT {
      scanner.get();
    } else {
      scanner.mark("ident?");
    }

    if scanner.sym != .PERIOD {
      scanner.mark("period?");
    }

  } else {
    scanner.mark("MODULE?");
  }
}


parse :: proc() {
  module();
}