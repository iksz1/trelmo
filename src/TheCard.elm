module TheCard exposing (TheCard, cardDecoder, cardEncoder)

import Json.Decode as D
import Json.Encode as E


type alias TheCard =
  { id : Int
  , text : String
  }


cardDecoder : D.Decoder TheCard
cardDecoder =
  D.map2 TheCard
    (D.field "id" D.int)
    (D.field "text" D.string)


cardEncoder : TheCard -> E.Value
cardEncoder card =
  E.object
    [ ( "id", E.int card.id )
    , ( "text", E.string card.text )
    ]
