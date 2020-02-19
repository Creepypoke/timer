module Main exposing (Model, Msg(..), init, main, subscriptions, update, view)

import Browser
import Duration exposing (Duration)
import Html exposing (..)
import Html.Attributes exposing (..)
import Task
import Time
import Time.Extra as TimeExtra



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
    }


smokeFreeTimestamp : Time.Posix
smokeFreeTimestamp =
    Time.millisToPosix 1579705200000



-- 22 Jan 2020 18:00


millisPerCigarette : Time.Posix
millisPerCigarette =
    Time.millisToPosix 4320000


init : () -> ( Model, Cmd Msg )
init _ =
    ( Model Time.utc (Time.millisToPosix 0)
    , Task.perform AdjustTimeZone Time.here
    )



-- UPDATE


type Msg
    = Tick Time.Posix
    | AdjustTimeZone Time.Zone


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



-- SUBSCRIPTIONS


subscriptions : Model -> Sub Msg
subscriptions _ =
    Time.every 1000 Tick



-- VIEW


getCigarettes : Time.Posix -> String
getCigarettes time =
    time
        |> Time.posixToMillis
        |> (\t -> t - (smokeFreeTimestamp |> Time.posixToMillis))
        |> toFloat
        |> (\t -> t / (millisPerCigarette |> Time.posixToMillis |> toFloat))
        |> String.fromFloat


view : Model -> Html Msg
view model =
    div []
        [ h1 [] [ text "You haven't smoked in " ]
        , viewTimer model.time
        , div [] [ text ("Cigarettes not smoked: " ++ getCigarettes model.time) ]
        , h1 [] [ text "!" ]
        ]


formatTimeValue : Float -> String
formatTimeValue value =
    value
        |> floor
        |> String.fromInt
        |> String.padLeft 2 '0'


viewTimer : Time.Posix -> Html Msg
viewTimer time =
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
