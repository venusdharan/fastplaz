unit cognitiveanalyze_integration;

{
  Cognitive Computer Vision Analyze
  https://www.microsoft.com/cognitive-services/en-us/computer-vision-api

  [x] USAGE
  with TCognitiveAnalyze.Create do
  begin
    Token := 'yourcognitivetoken;
    Model := 'celebrities';
    Result := Scan('imageURL');
    Free;
  end;


}

{$mode objfpc}{$H+}

interface

uses
  fpjson,
  common, http_lib, logutil_lib,
  Classes, SysUtils;

type

  { TCognitiveAnalyze }

  TCognitiveAnalyze = class(TInterfacedObject)
  private
    FCaption: string;
    FDetails: string;
    FFeatures: string;
    FImageURL: string;
    FToken: string;
    jsonData: TJSONData;
    function generateURL: string;
    function getData(APath: string): string;
  public
    constructor Create;
    destructor Destroy;

    property Token: string read FToken write FToken;
    property Features: string read FFeatures write FFeatures;
    property Details: string read FDetails write FDetails;
    property ImageURL: string read FImageURL write FImageURL;
    property Caption: string read FCaption;

    function Analyze: string;
    function Analyze(AImageURL: string): string;
    function AnalyzeAsJSON(AImageURL: string): string;
  end;

implementation

const
  _COGNITIVE_ANALYZE_URL =
    'https://westus.api.cognitive.microsoft.com/vision/v1.0/analyze?visualFeatures=%s&details=%s&language=en';

var
  Response: IHTTPResponse;

{ TCognitiveAnalyze }

function TCognitiveAnalyze.generateURL: string;
begin
  Result := Format(_COGNITIVE_ANALYZE_URL, [FFeatures, FDetails]);
end;

function TCognitiveAnalyze.getData(APath: string): string;
begin
  Result := '';
  try
    Result := jsonGetData(jsonData, APath);
  except
  end;
end;

constructor TCognitiveAnalyze.Create;
begin
  FFeatures := 'Description,Faces,Categories,Tags,Adult';
  FDetails := 'celebrities';
  FCaption := '';
end;

destructor TCognitiveAnalyze.Destroy;
begin
  if Assigned(jsonData) then
    jsonData.Free;
end;

function TCognitiveAnalyze.Analyze: string;
begin
  Result := Analyze(FImageURL);
end;

function TCognitiveAnalyze.Analyze(AImageURL: string): string;
var
  i: integer;
  _tags, s: string;
begin
  Result := AnalyzeAsJSON(AImageURL);
  if Result = '' then
    Exit;

  jsonData := GetJSON(Result);
  Result := getData('categories[0].detail.celebrities[0].name');
  if Result <> '' then
    Result := '*' + Result + '*'#10;

  if getData('adult.isAdultContent') = 'true' then
    Result := Result + 'sepertinya gambar dewasa.'#10;

  // get tags
  _tags := '';
  s := '';
  i := 0;
  repeat
    s := getData('tags[' + i2s(i) + '].name');
    _tags := _tags + ' ' + s;
    i := i + 1;
  until s = '';
  _tags := StringReplace(trim(_tags), ' ', ', ', [rfReplaceAll]);
  if _tags <> '' then
    Result := Result + _tags + '.'#10;

  FCaption := getData('description.captions[0].text');
end;

function TCognitiveAnalyze.AnalyzeAsJSON(AImageURL: string): string;
var
  _body: string;
begin
  Result := '';
  if FToken = '' then
    Exit;
  if AImageURL = '' then
    Exit;

  with THTTPLib.Create(generateURL) do
  begin
    try
      ContentType := 'application/json';
      AddHeader('Ocp-Apim-Subscription-Key', FToken);
      _body := '{"url":"' + AImageURL + '"}';
      RequestBody := TStringStream.Create(_body);
      Response := Post;
      if Response.ResultCode = 200 then
      begin
        Result := Response.ResultText;
      end;
    except
      on E: Exception do
        LogUtil.Add(E.Message, 'OCRANA');
    end;
    Free;
  end;
end;


end.