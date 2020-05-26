package main;
import "core:fmt";
import "core:os";
import "core:mem";

import "scanner";
import "parser";





main :: proc() {

  file, ok := os.read_entire_file("./sample2.ob");
  defer mem.delete(file);

  if(!ok) {
    fmt.println("Could not open input file");
    os.exit(1);
  }
  // TODO(josh): a whole copy just to insert a null terminator?  okay . . .
  // maybe we can just write our own read_entire_file function instead.  
  // or even memory mapped file?  That sounds fun
  source_stream := make([]byte, len(file) + 1);
  copy(source_stream, file);
  source_stream[len(file)] = 0;

  scanner.init(string(source_stream));
  scanner.get();
  parser.parse();
}