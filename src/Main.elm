module Main exposing (Model, Msg(..), init, main, subscriptions, update, view)

import Browser
import Duration exposing (Duration)
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (onInput)
import Task
import Time
import Time.Extra as TimeExtra
import Iso8601
import Debug
import Result



-- MAIN


main =
    Browser.element
        { init = init
        , view = view
        , update = update
        , subscriptions = subscriptions
        }



-- MODEL


type alias Model =
    { zone : Time.Zone
    , time : Time.Posix
    , smokeFreeTimestamp : Time.Posix -- 22 Jan 2020 18:00
    }



millisPerCigarette : Time.Posix
millisPerCigarette =
    Time.millisToPosix 4320000


init : () -> ( Model, Cmd Msg )
init _ =
    ( Model Time.utc (Time.millisToPosix 0) (Time.millisToPosix 1579705200000)
    , Task.perform AdjustTimeZone Time.here
    )



-- UPDATE


type Msg
    = Tick Time.Posix
    | AdjustTimeZone Time.Zone
    | Change String


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        Tick newTime ->
            ( { model | time = newTime }
            , Cmd.none
            )

        AdjustTimeZone newZone ->
            ( { model | zone = newZone }
            , Cmd.none
            )

        Change newContent ->
            ( { model | smokeFreeTimestamp = newContent
                |> Iso8601.toTime
                |> (\t -> Result.withDefault model.smokeFreeTimestamp t) }
            , Cmd.none
            )



-- SUBSCRIPTIONS


subscriptions : Model -> Sub Msg
subscriptions _ =
    Time.every 1000 Tick



-- VIEW


getCigarettes : Time.Posix -> Time.Posix -> String
getCigarettes time smokeFreeTimestamp =
    time
        |> Time.posixToMillis
        |> (\t -> t - (smokeFreeTimestamp |> Time.posixToMillis))
        |> toFloat
        |> (\t -> t / (millisPerCigarette |> Time.posixToMillis |> toFloat))
        |> String.fromFloat


toStringIso8601WithoutTime : Time.Posix -> String
toStringIso8601WithoutTime time =
    time
        |> Iso8601.fromTime
        |> String.split "T"
        |> List.head
        |> Maybe.withDefault ""

view : Model -> Html Msg
view model =
    div []
        [ h1 [] [ text "Best timer"]
            , viewTimer model.time model.smokeFreeTimestamp
        , div [] [
            div [] [text "I don't smoke since: "]
            , input [ placeholder "Text to reverse", value (toStringIso8601WithoutTime model.smokeFreeTimestamp), onInput Change, type_ "date" ] []
            ]
        , div [] [
                h2 [] [text "Additional information"]
                , div [] [ text ("Cigarettes not smoked: " ++ getCigarettes model.time model.smokeFreeTimestamp) ]
            ]
        ]


formatTimeValue : Float -> String
formatTimeValue value =
    value
        |> floor
        |> String.fromInt
        |> String.padLeft 2 '0'


viewTimer : Time.Posix -> Time.Posix -> Html Msg
viewTimer time smokeFreeTimestamp =
    let
        timeStampLeft =
            Duration.from smokeFreeTimestamp time

        days =
            timeStampLeft
                |> Duration.inDays
                |> formatTimeValue

        hour =
            timeStampLeft
                |> Duration.inHours
                |> (\t -> t - (Duration.inDays timeStampLeft |> floor |> toFloat) * 24)
                |> formatTimeValue

        minute =
            timeStampLeft
                |> Duration.inMinutes
                |> (\t -> t - (Duration.inHours timeStampLeft |> floor |> toFloat) * 60)
                |> formatTimeValue

        second =
            timeStampLeft
                |> Duration.inSeconds
                |> (\t -> t - (Duration.inMinutes timeStampLeft |> floor |> toFloat) * 60)
                |> formatTimeValue
    in
    div [ class "timer" ]
        [ div [ class "timer__values" ]
            [ div [] [ div [] [ text days ], div [] [ text "Days" ] ]
            , div [] [ div [] [ text hour ], div [] [ text "Hours" ] ]
            , div [] [ div [] [ text minute ], div [] [ text "Minutes" ] ]
            , div [] [ div [] [ text second ], div [] [ text "Seconds" ] ]
            ]
        ]
