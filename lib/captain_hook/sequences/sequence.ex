defmodule CaptainHook.Sequences.Sequence do
  use Ecto.Schema

  import Ecto.Changeset,
    only: [cast: 3, unique_constraint: 2, validate_required: 2]

  @type t :: %__MODULE__{
          livemode: boolean,
          name: binary,
          value: integer
        }

  @primary_key false
  schema "captain_hook_sequences" do
    field(:livemode, :boolean)
    field(:name, :string)
    field(:value, :integer, default: 0)
  end

  @spec create_changeset(Sequence.t(), map) :: Ecto.Changeset.t()
  def create_changeset(%__MODULE__{} = sequence, attrs) when is_map(attrs) do
    sequence
    |> cast(attrs, [:livemode, :name, :value])
    |> validate_required([:livemode, :name, :value])
    |> unique_constraint([:name, :livemode])
  end

  @spec update_changeset(Sequence.t(), map) :: Ecto.Changeset.t()
  def update_changeset(%__MODULE__{} = sequence, attrs) when is_map(attrs) do
    sequence
    |> cast(attrs, [:value])
    |> validate_required([:value])
  end
end
