defmodule CaptainHook.SequencesTest do
  use ExUnit.Case, async: false
  use CaptainHook.DataCase

  alias CaptainHook.Sequences

  describe "next/1" do
    test "with an invalid table_name, raises a FunctionClauseError" do
      assert_raise FunctionClauseError, fn ->
        Sequences.next("")
      end
    end

    test "with a valid table_name, returns the next sequence" do
      assert Sequences.next(:webhook_conversations) == 1
      assert Sequences.next(:webhook_conversations) == 2
    end
  end
end
