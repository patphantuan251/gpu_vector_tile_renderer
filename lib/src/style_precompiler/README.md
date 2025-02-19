# style_precompiler

NOTE: experimental code - beware. unreadable mess ahead. will be rewritten once it's working.

Contains all necessary tools to precompile a given JSON style to a Dart class and shaders.

Used by `bin/precompile_style.dart`.

NOTE: Styles have to be precompiled due to a current limitation with flutter_gpu - it does not support dynamic shader compilation. Once this is remedied, the code in the style compiler can be moved to the runtime.
