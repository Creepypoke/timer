port module PortMain exposing (cache)

import Json.Encode as E

port cache : E.Value -> Cmd msg