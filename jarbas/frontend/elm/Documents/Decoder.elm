module Documents.Decoder exposing (..)

import Documents.Inputs.Update as InputsUpdate
import Documents.Receipt.Decoder as ReceiptDecoder
import Documents.Supplier.Model as SupplierModel
import Internationalization exposing (Language(..), TranslationId(..), translate)
import Json.Decode exposing ((:=), Decoder, int, list, maybe, string)
import Json.Decode.Pipeline exposing (decode, hardcoded, nullable, required)
import String
import Documents.Model exposing (Model, Document, Results, results)


getPage : List ( String, String ) -> Maybe Int
getPage query =
    let
        tuple =
            List.head <|
                List.filter
                    (\( name, value ) ->
                        if name == "page" then
                            True
                        else
                            False
                    )
                    query
    in
        case tuple of
            Just ( name, value ) ->
                case String.toInt value of
                    Ok num ->
                        Just num

                    Err e ->
                        Nothing

            Nothing ->
                Nothing


decoder : Language -> String -> List ( String, String ) -> Decoder Results
decoder lang apiKey query =
    let
        current =
            Maybe.withDefault 1 (getPage query)
    in
        decode Results
            |> required "results" (list <| singleDecoder lang apiKey)
            |> required "count" (nullable int)
            |> required "previous" (nullable string)
            |> required "next" (nullable string)
            |> hardcoded Nothing
            |> hardcoded current
            |> hardcoded ""


singleDecoder : Language -> String -> Decoder Document
singleDecoder lang apiKey =
    let
        supplier =
            SupplierModel.model
    in
        decode Document
            |> required "id" int
            |> required "document_id" int
            |> required "congressperson_name" string
            |> required "congressperson_id" int
            |> required "congressperson_document" int
            |> required "term" int
            |> required "state" string
            |> required "party" string
            |> required "term_id" int
            |> required "subquota_number" int
            |> required "subquota_description" string
            |> required "subquota_group_id" int
            |> required "subquota_group_description" string
            |> required "supplier" string
            |> required "cnpj_cpf" string
            |> required "document_number" string
            |> required "document_type" int
            |> required "issue_date" (nullable string)
            |> required "document_value" string
            |> required "remark_value" string
            |> required "net_value" string
            |> required "month" int
            |> required "year" int
            |> required "installment" int
            |> required "passenger" string
            |> required "leg_of_the_trip" string
            |> required "batch_number" int
            |> required "reimbursement_number" int
            |> required "reimbursement_value" string
            |> required "applicant_id" int
            |> required "receipt" (ReceiptDecoder.decoder lang)
            |> hardcoded { supplier | googleStreetViewApiKey = apiKey }


updateDocumentLanguage : Language -> Document -> Document
updateDocumentLanguage lang document =
    let
        receipt =
            document.receipt

        newReceipt =
            { receipt | lang = lang }

        supplier =
            document.supplier_info

        newSupplier =
            { supplier | lang = lang }
    in
        { document | receipt = newReceipt, supplier_info = newSupplier }


updateLanguage : Language -> Model -> Model
updateLanguage lang model =
    let
        results =
            model.results

        newDocuments =
            List.map (updateDocumentLanguage lang) model.results.documents

        newResults =
            { results | documents = newDocuments }

        newInputs =
            InputsUpdate.updateLanguage lang model.inputs
    in
        { model | lang = lang, inputs = newInputs, results = newResults }


updateGoogleStreetViewApiKey : String -> Model -> Model
updateGoogleStreetViewApiKey key model =
    { model | googleStreetViewApiKey = key }
