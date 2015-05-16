defmodule Entice.Entity.BehaviourTest do
  use ExUnit.Case, async: true


  defmodule CompilationTestBehaviour do
    use Entice.Entity.Behaviour
    # test if the compiler can make sense of what the macro produces
  end
end
