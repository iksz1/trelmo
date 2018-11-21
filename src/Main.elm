port module Main exposing (..)

import Task
import Browser
import Browser.Dom as Dom
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (..)
import Html.Keyed as Keyed
import Html.Lazy exposing (lazy, lazy2)
import Json.Decode as D
import Json.Encode as E
import TheList exposing (..)
import TheCard exposing (..)


main =
  Browser.element
    { init = init
    , update = updateWithStorage
    , subscriptions = subscriptions
    , view = view
    }


port setStorage : E.Value -> Cmd msg



-- MODEL


type alias Model =
  { lists : List TheList
  , isModalOpen : Bool
  , onModalAccept : Msg
  , uid : Int
  , inputValue : String
  }



modelDecoder : D.Decoder Model
modelDecoder =
  D.map5 Model
    (D.field "lists" (D.list listDecoder))
    (D.succeed False)
    (D.succeed DoNothing)
    (D.field "uid" D.int)
    (D.succeed "")


modelEncoder : Model -> E.Value
modelEncoder model =
  E.object
    [ ("uid", E.int model.uid)
    , ("lists", E.list listEncoder model.lists)
    ]


decodeModel : String -> Model
decodeModel str =
  let
    result =
      D.decodeString modelDecoder str
  in
  case result of
    Ok model ->
      model
    Err err ->
      Model [] False DoNothing 0 ""



init : Maybe String -> ( Model, Cmd Msg )
init maybeStr =
  ( decodeModel (Maybe.withDefault "" maybeStr)
  , Cmd.none
  )



-- UPDATE


type Msg
  = DoNothing
  | AddList
  | UpdateList Int
  | RemoveList Int
  | AddCard Int
  | UpdateCard Int Int
  | RemoveCard Int Int
  | ChangeInputValue String
  | ShowModal String Msg
  | CloseModal Bool


updateWithStorage : Msg -> Model -> ( Model, Cmd Msg )
updateWithStorage msg model =
  let
    ( newModel, cmds ) =
        update msg model
  in
  ( newModel
  , Cmd.batch [ setStorage (modelEncoder newModel), cmds ]
  )


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
  case msg of
    DoNothing ->
      ( model, Cmd.none )

    AddCard listId ->
      let
        updateList : TheList -> TheList
        updateList list =
          if list.id == listId then
            { list | cards = list.cards ++ [ { id = model.uid, text = model.inputValue } ] }
          else
            list
      in
      ( { model
        | lists = List.map updateList model.lists
        , uid = model.uid + 1
        }
      , Cmd.none
      )

    UpdateCard listId id ->
      let
        updateList : TheList -> TheList
        updateList list =
          if list.id == listId then
            { list | cards = List.map (\c -> if c.id == id then { c | text = model.inputValue } else c) list.cards }
          else
            list
      in
      ( { model | lists = List.map updateList model.lists }
      , Cmd.none
      )

    RemoveCard listId id ->
      let
        updateList : TheList -> TheList
        updateList list =
          if list.id == listId then
            { list | cards = List.filter (\c -> c.id /= id) list.cards }
          else
            list
      in
      ( { model | lists = List.map updateList model.lists }
      , Cmd.none
      )

    AddList ->
      ( { model
        | lists = model.lists ++ [ { id = model.uid, text = model.inputValue, cards = [] } ]
        , uid = model.uid + 1
        }
      , Cmd.none
      )

    UpdateList id ->
      let
        updateList : TheList -> TheList
        updateList list =
          if list.id == id then
            { list | text = model.inputValue }
          else
            list
      in
      ( { model | lists = List.map updateList model.lists }
      , Cmd.none
      )

    RemoveList id ->
      ( { model | lists = List.filter (\l -> l.id /= id) model.lists }
      , Cmd.none
      )

    ShowModal val onAccept ->
      ( { model
        | isModalOpen = True
        , inputValue = val
        , onModalAccept = onAccept
        }
      , Task.attempt (\_ -> DoNothing) (Dom.focus "modal-input")
      )
    
    CloseModal isAccepted ->
      if isAccepted then
        if String.isEmpty <| String.trim <| model.inputValue then
          ( model, Cmd.none )
        else
          updateWithStorage model.onModalAccept { model | isModalOpen = False }
      else
        ( { model | isModalOpen = False }
        , Cmd.none
        )

    ChangeInputValue text ->
      ( { model | inputValue = text }
      , Cmd.none
      )



-- SUBSCRIPTIONS


subscriptions : Model -> Sub Msg
subscriptions model =
  Sub.none



-- VIEW


view : Model -> Html Msg
view model =
  div [ class "main-content" ]
    [ Keyed.ul [ class "lists" ] (List.map viewKeyedList model.lists)
    , button [ onClick (ShowModal "" AddList) ] [ text "add list" ]
    , if model.isModalOpen then
        viewModal model.inputValue ChangeInputValue
      else
        text ""
    ]


viewKeyedList : TheList -> ( String, Html Msg )
viewKeyedList list =
  ( String.fromInt list.id, lazy viewList list )


viewList : TheList -> Html Msg
viewList list =
  li [ class "list-wrap" ]
    [ h3 [ class "list-title", onDoubleClick (ShowModal list.text (UpdateList list.id)) ] [ text list.text ]
    , button [ onClick (RemoveList list.id) ] [ text "X" ]
    , Keyed.ul [] (List.map (viewKeyedCard list.id) list.cards)
    , button [ onClick (ShowModal "" (AddCard list.id)) ] [ text "add card" ]
    ]


viewKeyedCard : Int -> TheCard -> ( String, Html Msg )
viewKeyedCard listId card =
  ( String.fromInt card.id, lazy2 viewCard listId card )


viewCard : Int -> TheCard -> Html Msg
viewCard listId card =
  li
    [ class "card-wrap"
    , onDoubleClick (ShowModal card.text (UpdateCard listId card.id))
    ]
    [ text card.text
    , button [ onClick (RemoveCard listId card.id) ] [ text "X" ]
    ]


viewModal : String -> (String -> Msg) -> Html Msg
viewModal inputValue inputHandler =
  div
    [ class "modal-outer"
    , onClick (CloseModal False)
    , onEsc (CloseModal False)
    ]
    [ div
        [ class "modal-inner"
        , stopPropagationOn "click" (D.succeed (DoNothing, True))
        ]
        [ viewInput inputValue inputHandler (CloseModal True)
        , button [ onClick (CloseModal True) ] [ text "OK" ]
        , button [ onClick (CloseModal False) ] [ text "Cancel" ]
        ]
    ]


viewInput : String -> (String -> Msg) -> Msg -> Html Msg
viewInput val msgIn msgEn =
  input
    [ type_ "text"
    , id "modal-input"
    , value val
    , autofocus True
    , onInput msgIn
    , onEnter msgEn
    ]
    []


onEnter : Msg -> Attribute Msg
onEnter msg = 
  onSpecificKeyDown 13 msg


onEsc : Msg -> Attribute Msg
onEsc msg = 
  onSpecificKeyDown 27 msg


onSpecificKeyDown : Int -> Msg -> Attribute Msg
onSpecificKeyDown key msg =
  let
    tagger code =
      if code == key then
        D.succeed msg
      else
        D.fail "different key"
  in
  on "keydown" (D.andThen tagger keyCode)
