module Main exposing (Model, Msg(..), init, main, subscriptions, update, view)

import Browser
import Browser.Navigation as Nav
import Duration
import Html exposing (..)
import Html.Attributes exposing (class, href, placeholder, type_, value)
import Html.Events exposing (onInput)
import Iso8601
import PortMain
import Result
import Round
import Task
import Time
import Url



-- MAIN


main =
    Browser.application
        { init = init
        , onUrlChange = UrlChanged
        , onUrlRequest = LinkClicked
        , subscriptions = subscriptions
        , update = update
        , view = view
        }



-- MODEL


type alias Model =
    { key : Nav.Key
    , url : Url.Url
    , zone : Time.Zone
    , time : Time.Posix
    , smokeFreeTimestamp : Time.Posix -- 22 Jan 2020 18:00
    }


millisPerCigarette : Time.Posix
millisPerCigarette =
    Time.millisToPosix 4320000


init : Maybe Int -> Url.Url -> Nav.Key -> ( Model, Cmd Msg )
init flag url key =
    let
        verifiedInitDate =
            flag
                |> Maybe.withDefault 1579705200000
                |> Time.millisToPosix
    in
    ( Model key url Time.utc verifiedInitDate verifiedInitDate
    , Task.perform AdjustTimeZone Time.here
    )



-- UPDATE


type Msg
    = Tick Time.Posix
    | AdjustTimeZone Time.Zone
    | Change String
    | LinkClicked Browser.UrlRequest
    | UrlChanged Url.Url


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        LinkClicked urlRequest ->
            case urlRequest of
                Browser.Internal url ->
                    ( model, Nav.pushUrl model.key (Url.toString url) )

                Browser.External href ->
                    ( model, Nav.load href )

        UrlChanged url ->
            ( { model | url = url }
            , Cmd.none
            )

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


view : Model -> Browser.Document Msg
view model =
    let
        headerPart =
            [ navigationMenu model.url
            , h1 [] [ text "Best timer" ]
            ]

        bodyPart =
            if model.url.path == "/" then
                viewMain model

            else
                viewSettings model
    in
    { title = "Best Timer"
    , body =
        [ div [ class "main" ]
            (List.concat
                [ headerPart, bodyPart ]
            )
        ]
    }


viewMain : Model -> List (Html Msg)
viewMain model =
    [ viewTimer model.time model.smokeFreeTimestamp
    , timerInput model.zone model.smokeFreeTimestamp
    , viewAdditionalBlock model.time model.smokeFreeTimestamp
    ]


viewSettings : Model -> List (Html Msg)
viewSettings model =
    [ h2 [] [ text "Settings" ]
    ]


type RouteName
    = Home
    | Settings


type alias Route =
    { name : RouteName
    , path : String
    }


routesList =
    [ Route Home "/"
    , Route Settings "/settings"
    ]


activeRoute : Url.Url -> String -> Bool
activeRoute url path =
    url.path == path


navigationMenu : Url.Url -> Html Msg
navigationMenu currentUrl =
    nav [ class "navigation" ]
        [ ul [ class "navigation__list" ]
            [ navigationElement "/" "Main" (activeRoute currentUrl "/")
            , navigationElement "/settings" "Settings" (activeRoute currentUrl "/settings")
            ]
        ]


navigationElement : String -> String -> Bool -> Html Msg
navigationElement path label active =
    let
        className =
            if active then
                "navigation__list__element active"

            else
                "navigation__list__element"
    in
    li [ class className ] [ a [ class "navigation__list__element_link", href path ] [ text label ] ]


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


toStringIso8601WithoutTime : Time.Posix -> String
toStringIso8601WithoutTime time =
    time
        |> Iso8601.fromTime
        |> String.split "T"
        |> List.head
        |> Maybe.withDefault ""


timerInput : Time.Zone -> Time.Posix -> Html Msg
timerInput zone smokeFreeTimestamp =
    let
        isoDateSmokeFree =
            toStringIso8601WithoutTime smokeFreeTimestamp

        smokeFreeYear =
            smokeFreeTimestamp |> Time.toYear zone |> String.fromInt

        smokeFreeMonth =
            smokeFreeTimestamp |> Time.toMonth zone |> toPrettyMonth

        smokeFreeDays =
            smokeFreeTimestamp |> Time.toDay zone |> String.fromInt

        prettyDateSmokeFree =
            smokeFreeYear ++ " " ++ smokeFreeMonth ++ " " ++ smokeFreeDays
    in
    label [ class "stopSince" ]
        [ div [ class "stopSince_text" ] [ text "🚭 since: " ]
        , input [ class "stopSince_input invisible", placeholder "Text to reverse", value isoDateSmokeFree, onInput Change, type_ "date" ] []
        , div [ class "stopSince_date" ] [ text prettyDateSmokeFree ]
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
