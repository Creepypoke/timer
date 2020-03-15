module Main exposing (Model, Msg(..), init, main, subscriptions, update, view)

import Browser
import Duration
import Html exposing (..)
import Html.Attributes exposing (class, placeholder, type_, value)
import Html.Events exposing (onInput)
import Iso8601
import PortMain
import Result
import Round
import Task
import Time



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


init : Maybe Int -> ( Model, Cmd Msg )
init flag =
    let
        verifiedInitDate =
            flag
                |> Maybe.withDefault 1579705200000
                |> Time.millisToPosix
    in
    ( Model Time.utc verifiedInitDate verifiedInitDate
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

        Change newDate ->
            ( { model
                | smokeFreeTimestamp =
                    newDate
                        |> Iso8601.toTime
                        |> Result.withDefault model.smokeFreeTimestamp
              }
            , PortMain.maybeCache newDate
            )



-- SUBSCRIPTIONS


subscriptions : Model -> Sub Msg
subscriptions _ =
    Time.every 1000 Tick



-- VIEW


getCigarettes : Time.Posix -> Time.Posix -> Float
getCigarettes time smokeFreeTimestamp =
    time
        |> Time.posixToMillis
        |> (\t -> t - (smokeFreeTimestamp |> Time.posixToMillis))
        |> toFloat
        |> (\t -> t / (millisPerCigarette |> Time.posixToMillis |> toFloat))


toStringIso8601WithoutTime : Time.Posix -> String
toStringIso8601WithoutTime time =
    time
        |> Iso8601.fromTime
        |> String.split "T"
        |> List.head
        |> Maybe.withDefault ""


toPrettyMonth : Time.Month -> String
toPrettyMonth month =
    case month of
        Time.Jan ->
            "January"

        Time.Feb ->
            "February"

        Time.Mar ->
            "March"

        Time.Apr ->
            "April"

        Time.May ->
            "May 🎂"

        Time.Jun ->
            "June"

        Time.Jul ->
            "July"

        Time.Aug ->
            "August"

        Time.Sep ->
            "September"

        Time.Oct ->
            "October"

        Time.Nov ->
            "November"

        Time.Dec ->
            "December 🎄"


view : Model -> Html Msg
view model =
    let
        isoDateSmokeFree =
            toStringIso8601WithoutTime model.smokeFreeTimestamp

        smokeFreeYear =
            model.smokeFreeTimestamp |> Time.toYear model.zone |> String.fromInt

        smokeFreeMonth =
            model.smokeFreeTimestamp |> Time.toMonth model.zone |> toPrettyMonth

        smokeFreeDays =
            model.smokeFreeTimestamp |> Time.toDay model.zone |> String.fromInt

        prettyDateSmokeFree =
            smokeFreeYear ++ " " ++ smokeFreeMonth ++ " " ++ smokeFreeDays
    in
    div [ class "main" ]
        [ h1 [] [ text "Best timer" ]
        , viewTimer model.time model.smokeFreeTimestamp
        , label [ class "stopSince" ]
            [ div [ class "stopSince_text" ] [ text "🚭 since: " ]
            , input [ class "stopSince_input invisible", placeholder "Text to reverse", value isoDateSmokeFree, onInput Change, type_ "date" ] []
            , div [ class "stopSince_date" ] [ text prettyDateSmokeFree ]
            ]
        , viewAdditionalBlock model.time model.smokeFreeTimestamp
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
            [ div [ class "timer__values_cell" ] [ div [ class "timer__values_value" ] [ text days ], div [ class "timer__values_title" ] [ text "Days" ] ]
            , div [ class "timer__values_cell" ] [ div [ class "timer__values_value" ] [ text hour ], div [ class "timer__values_title" ] [ text "Hours" ] ]
            , div [ class "timer__values_cell" ] [ div [ class "timer__values_value" ] [ text minute ], div [ class "timer__values_title" ] [ text "Minutes" ] ]
            , div [ class "timer__values_cell" ] [ div [ class "timer__values_value" ] [ text second ], div [ class "timer__values_title" ] [ text "Seconds" ] ]
            ]
        ]


viewAdditionalBlock : Time.Posix -> Time.Posix -> Html Msg
viewAdditionalBlock time smokeFreeTimestamp =
    let
        notSmokedCigarettes =
            getCigarettes time smokeFreeTimestamp

        notSmokedPacks =
            (notSmokedCigarettes / 20) |> Round.round 1

        notSpendMoney =
            (notSmokedCigarettes / 20 * 169) |> Round.round 2
    in
    label [ class "additional-information" ]
        [ h2 [] [ text "Additional information" ]
        , input [ type_ "checkbox", class "additional-information_indicator invisible" ] []
        , div [ class "additional-information_body" ]
            [ div [] [ text ("🚬: " ++ (notSmokedCigarettes |> Round.round 4) ++ " (" ++ notSmokedPacks ++ " packs)") ]
            , div [] [ text ("💰: " ++ notSpendMoney ++ " ₽") ]
            ]
        ]
