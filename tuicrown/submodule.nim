# This is just an example to get you started. Users of your library will
# import this file by writing ``import tuicrown/submodule``. Feel free to rename or
# remove this file altogether. You may create additional modules alongside
# this file as required.

type
  Submodule* = object
    name*: string

template todo*() =
  assert(false, "Not Implemented")

proc initSubmodule*(): Submodule =
  ## Initialises a new ``Submodule`` object.
  Submodule(name: "Anonymous")
