import Base
import ./relational_syntax_equal.bend as Same
import ../surface/parser.bend as Parser
import ../surface/syntax.bend as Syntax
import ../kernel/error.bend as E

# C1 crib probe (unit C, crib section L4). Source: W/c1-print-probe.bend; the
# runner W/c1-crib.sh copies it to bend2/tests/ for the build and removes the copy.
# Mode `t1 <text>`: Syntax.print of the parsed text. Mode `same <text>`: is the
# Decl list of the text equal to the Decl list of its printed text?

def message_result(-A: Data, result: Result<&2, &2, E.T, A>) -> Result<&2, &2, String, A>:
  match result:
    case Fail{error}: Fail{E.message(error)}
    case Done{value}: Done{value}

def parsed(source: String) -> Result<&2, &2, String, List<&2, Syntax.Decl>>:
  message_result(List<&2, Syntax.Decl>, Parser.program(source))

def t1_text(r: Result<&2, &2, String, List<&2, Syntax.Decl>>) -> String:
  match r:
    case Fail{error}: "PARSE-FAIL " ++ error ++ "\n"
    case Done{value}: Syntax.print(value)

def same(source: String) -> Result<&2, &2, String, Bool>:
  do Result<&2, &2, String, Bool>:
    +first : List<&2, Syntax.Decl> <- parsed(source)
    second : List<&2, Syntax.Decl> <- parsed(Syntax.print(first))
    return Same.declarations(first, second)

def same_text(r: Result<&2, &2, String, Bool>) -> String:
  match r:
    case Fail{error}: "PARSE-FAIL " ++ error ++ "\n"
    case Done{value}: Bool.pick(String, value, "SAME\n", "DIFFERENT\n")

type Md is Data:
  MT1{}
  MSame{}
  MNone{}

def mode_of(+mode: String) -> Md:
  Bool.pick(Md, String.eq(mode, "t1"), MT1{}, Bool.pick(Md, String.eq(mode, "same"), MSame{}, MNone{}))

def run_mode(m: Md, src: String) -> String:
  match m:
    case MT1{}:
      t1_text(parsed(src))
    case MSame{}:
      same_text(same(src))
    case MNone{}:
      "unknown mode\n"

def run_args(args: List<String>) -> String:
  match args:
    case Con{mode, Con{src, rest}}:
      run_mode(mode_of(mode), src)
    case other:
      "usage: zz_c1_print_probe.bend <t1|same> <source text>\n"

def main() -> IO(Unit):
  do IO<Unit>:
    args : List<String> <- IO.args()
    IO.write(run_args(args))
