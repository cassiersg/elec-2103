// DO NOT EDIT - file generated by game/gen_huffman.py
if ((code >> 0) & 0x1) {
 decoded = 0xff334c4c;
 code_len = 1;
} else {
 if ((code >> 1) & 0x1) {
  if ((code >> 2) & 0x1) {
   decoded = 0xffeaeaea;
   code_len = 3;
  } else {
   if ((code >> 3) & 0x1) {
    if ((code >> 4) & 0x1) {
     decoded = 0xff1e1e1e;
     code_len = 5;
    } else {
     if ((code >> 5) & 0x1) {
      decoded = 0xff3b3b3b;
      code_len = 6;
     } else {
      if ((code >> 6) & 0x1) {
       decoded = 0xffeaea00;
       code_len = 7;
      } else {
       decoded = 0xff3b3b00;
       code_len = 7;
      }
     }
    }
   } else {
    if ((code >> 4) & 0x1) {
     decoded = 0xff494949;
     code_len = 5;
    } else {
     if ((code >> 5) & 0x1) {
      if ((code >> 6) & 0x1) {
       decoded = 0xff3b0000;
       code_len = 7;
      } else {
       if ((code >> 7) & 0x1) {
        if ((code >> 8) & 0x1) {
         decoded = 0xff930000;
         code_len = 9;
        } else {
         decoded = 0xff939393;
         code_len = 9;
        }
       } else {
        decoded = 0xff939300;
        code_len = 8;
       }
      }
     } else {
      decoded = 0xffea0000;
      code_len = 6;
     }
    }
   }
  }
 } else {
  decoded = 0xff757575;
  code_len = 2;
 }
}