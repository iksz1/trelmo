import Array
import Task
import Browser
import Browser.Dom as Dom
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (..)
import Html.Keyed as Keyed
import Json.Decode as Json


main =
  Browser.element
    { init = init
    , update = update
    , subscriptions = subscriptions
    , view = view
    }



-- MODEL


type alias TheCard =
  { id : Int
  , text : String
  }


type alias TheList =
  { id : Int
  , text : String
  , cards : List TheCard
  }


type alias Model =
  { lists : List TheList
  , isModalOpen : Bool
  , onModalAccept : Msg
  , uid : Int
  , inputValue : String
  }


init : () -> ( Model, Cmd Msg )
init _ =
  ( Model [] False DoNothing 0 ""
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
      ( { model
        | lists =
            List.map
              (\l ->
                if l.id == id then
                  { l | text = model.inputValue }
                else
                  l
              )
              model.lists
        }
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
        update model.onModalAccept { model | isModalOpen = False }
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


viewCard : Int -> TheCard -> ( String, Html Msg )
viewCard listId card =
  ( String.fromInt card.id
  , li
      [ class "card-wrap"
      , onDoubleClick (ShowModal card.text (UpdateCard listId card.id))
      ]
      [ text card.text
      , button [ onClick (RemoveCard listId card.id) ] [ text "X" ]
      ]
  )


viewList : TheList -> ( String, Html Msg )
viewList list =
  ( String.fromInt list.id
  , li [ class "list-wrap" ]
      [ h3 [ class "list-title", onDoubleClick (ShowModal list.text (UpdateList list.id)) ] [ text list.text ]
      , button [ onClick (RemoveList list.id) ] [ text "X" ]
      , Keyed.ul [] (List.map (viewCard list.id) list.cards)
      , button [ onClick (ShowModal "" (AddCard list.id)) ] [ text "add card" ]
      ]
  )


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

viewModal : String -> (String -> Msg) -> Html Msg
viewModal inputValue inputHandler =
  div
    [ class "modal-outer"
    , onClick (CloseModal False)
    , onEsc (CloseModal False)
    ]
    [ div
        [ class "modal-inner"
        , stopPropagationOn "click" (Json.succeed (DoNothing, True))
        ]
        [ viewInput inputValue inputHandler (CloseModal True)
        , button [ onClick (CloseModal True) ] [ text "OK" ]
        , button [ onClick (CloseModal False) ] [ text "Cancel" ]
        ]
    ]

onEsc : Msg -> Attribute Msg
onEsc msg =
  let
    isEsc code =
      if code == 27 then
        Json.succeed msg
      else
        Json.fail "not ENTER"
  in
  on "keydown" (Json.andThen isEsc keyCode)

onEnter : Msg -> Attribute Msg
onEnter msg = 
  let
    isEnter code =
      if code == 13 then
        Json.succeed msg
      else
        Json.fail "not ENTER"
  in
  on "keydown" (Json.andThen isEnter keyCode)


view : Model -> Html Msg
view model =
  div [ class "main-content" ]
    [ Keyed.ul [ class "lists" ] (List.map viewList model.lists)
    , button [ onClick (ShowModal "" AddList) ] [ text "add list" ]
    , if model.isModalOpen then
        viewModal model.inputValue ChangeInputValue
      else
        text ""
    ]
