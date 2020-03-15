port module PortMain exposing (cache, maybeCache)

import Iso8601
import Json.Encode as E
import Result
import Time


port cache : E.Value -> Cmd msg


maybeCache : String -> Cmd msg
maybeCache inputDate =
    inputDate
        |> Iso8601.toTime
        |> Result.toMaybe
        |> (\mInput ->
                case mInput of
                    Nothing ->
                        Cmd.none

                    Just time ->
                        time
                            |> Time.posixToMillis
                            |> E.int
                            |> cache
           )
