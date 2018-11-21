module TheList exposing (TheList, listDecoder, listEncoder)

import Json.Decode as D
import Json.Encode as E
import TheCard exposing (..)


type alias TheList =
  { id : Int
  , text : String
  , cards : List TheCard
  }


listDecoder : D.Decoder TheList
listDecoder =
  D.map3 TheList
    (D.field "id" D.int)
    (D.field "text" D.string)
    (D.field "cards" (D.list cardDecoder))


listEncoder : TheList -> E.Value
listEncoder list =
  E.object
    [ ("id", E.int list.id)
    , ("text", E.string list.text)
    , ("cards", E.list cardEncoder list.cards)
    ]
