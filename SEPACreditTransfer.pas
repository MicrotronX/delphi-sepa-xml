//
//   Delphi unit for SEPA credit transfer XML file creation
//   (beta version 0.2.0, 2014-02-20)
//
//   Copyright (C) 2013-2014 by Aaron Spettl
//
//   This program is free software; you can redistribute it and/or modify
//   it under the terms of the GNU General Public License as published by
//   the Free Software Foundation; either version 2 of the License, or
//   (at your option) any later version.
//
//   This program is distributed in the hope that it will be useful,
//   but WITHOUT ANY WARRANTY; without even the implied warranty of
//   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//   GNU General Public License for more details.
//
//   You should have received a copy of the GNU General Public License
//   along with this program; if not, write to the Free Software
//   Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA  02111-1307, USA.
//
//   Author:  Aaron Spettl
//            Virchowstr. 26
//            89075 Ulm
//            Germany
//   E-mail:  aaron@spettl.de
//
unit SEPACreditTransfer;

{$IFDEF FPC}                // Lazarus: set compiler mode and file encoding
{%encoding CP1252}
{$mode objfpc}{$H+}
{$ENDIF}

interface

uses
  SysUtils, Classes, DateUtils, SEPACommon;

type
  // In the following, all necessary classes to create credit transfers for
  // SEPA XML files are introduced. Please have a look at the specification of
  // the XML data format at
  //   http://www.ebics.de/index.php?id=77
  // (section 2.2.2, "Anlage3_Datenformate_V2.7.pdf" by EBICS, Die Deutsche Kreditwirtschaft).
  //
  // Short explanation of XML file for credit transfers:
  //
  // XML tags                      corresponding class
  // ---------------------------------------------------------------------------
  // <Document>                    TCreditTransferInitiation
  //   <CstmrCdtTrfInitn>          TCreditTransferInitiation
  //     <PmtInf>                  TCreditTransferPaymentInformation
  //       <CdtTrfTxInf>           TCreditTransferTransactionInformation
  //       <CdtTrfTxInf>           ...
  //         ...
  //     <PmtInf>
  //       ...
  //
  // Note that all strings in these units are interpreted with respect to the
  // default behavior of the development environment, i.e.,
  // a) for Delphi < 2009:  ANSI strings
  // b) for Delphi >= 2009: Unicode strings
  // c) for Lazarus:        no encoding specified, ANSI is assumed

  TCreditTransferTransactionInformation = class
  private
    fPmtIdEndToEndId: String;                          // end-to-end identification of this payment (by default "NOTPROVIDED")
    fInstdAmtCcy: String;                              // instructed amount, currency (always "EUR")
    fInstdAmt: Currency;                               // instructed amount
    fCdtrAgt: TFinancialInstitution;                   // creditor agent
    fCdtrNm: String;                                   // creditor name
    fCdtrAcct: TAccountIdentification;                 // creditor account identification
    fRmtInfUstrd: String;                              // unstructured remittance information

    procedure SetCdtrNm(const str: String);
    procedure SetRmtInfUstrd(const str: String);
  public
    constructor Create;

    property PmtIdEndToEndId: String read fPmtIdEndToEndId write fPmtIdEndToEndId;
    property InstdAmtCcy: String read fInstdAmtCcy write fInstdAmtCcy;
    property InstdAmt: Currency read fInstdAmt write fInstdAmt;
    property CdtrAgt: TFinancialInstitution read fCdtrAgt;
    property CdtrNm: String read fCdtrNm write SetCdtrNm;
    property CdtrAcct: TAccountIdentification read fCdtrAcct;
    property RmtInfUstrd: String read fRmtInfUstrd write SetRmtInfUstrd;

    function Validate(const schema: String): TStringList;
    procedure SaveToStream(const stream: TStream; const schema: String);
  end;

  TCreditTransferPaymentInformation = class
  private
    fPmtInfId: String;                                 // payment information identification
    fPmtMtd: String;                                   // payment method (always "TRF")
    fPmtTpInfSvcLvlCd: String;                         // payment type, service level code (always "SEPA")
    fPmtTpInfInstrPrty: String;                        // payment type, instruction priority ("NORM" or "HIGH")
    fReqdExctnDt: TDateTime;                           // requested execution date
    fDbtrNm: String;                                   // creditor name
    fDbtrAcct: TAccountIdentification;                 // creditor account identification
    fDbtrAgt: TFinancialInstitution;                   // creditor agent
    fChrgBr: String;                                   // charge bearer (always "SLEV")
    fCdtTrfTxInf: array of TCreditTransferTransactionInformation;

    procedure SetDbtrNm(const str: String);

    function GetCtrlSum: Currency;
    function GetCdtTrfTxInfEntry(const i: Integer): TCreditTransferTransactionInformation;
    function GetCdtTrfTxInfCount: Integer;
  public
    constructor Create;

    property PmtInfId: String read fPmtInfId write fPmtInfId;
    property PmtMtd: String read fPmtMtd write fPmtMtd;
    property NbOfTxs: Integer read GetCdtTrfTxInfCount;
    property CtrlSum: Currency read GetCtrlSum;
    property PmtTpInfSvcLvlCd: String read fPmtTpInfSvcLvlCd write fPmtTpInfSvcLvlCd;
    property PmtTpInfInstrPrty: String read fPmtTpInfInstrPrty write fPmtTpInfInstrPrty;
    property ReqdExctnDt: TDateTime read fReqdExctnDt write fReqdExctnDt;
    property DbtrNm: String read fDbtrNm write SetDbtrNm;
    property DbtrAcct: TAccountIdentification read fDbtrAcct;
    property DbtrAgt: TFinancialInstitution read fDbtrAgt;
    property ChrgBr: String read fChrgBr write fChrgBr;

    procedure AppendCdtTrfTxInfEntry(const transaction: TCreditTransferTransactionInformation);
    property CdtTrfTxInfEntry[const i: Integer]: TCreditTransferTransactionInformation read GetCdtTrfTxInfEntry;
    property CdtTrfTxInfCount: Integer read GetCdtTrfTxInfCount;

    function Validate(const schema: String): TStringList;
    procedure SaveToStream(const stream: TStream; const schema: String);
  end;

  TCreditTransferInitiation = class
  private
    fSchema: String;                                   // ISO schema, e.g. "pain.001.002.03", empty means auto-select based on date
    fGrpHdrMsgId: String;                              // group header: message identification
    fGrpHdrCreDtTm: TDateTime;                         // group header: time of file creation
    fGrpHdrInitgPtyName: String;                       // group header: initiator name
    fPmtInf: array of TCreditTransferPaymentInformation;

    function GetSchema: String;
    procedure SetGrpHdrInitgPtyName(const str: String);

    function GetGrpHdrNbOfTxs: Integer;
    function GetPmtInfEntry(const i: Integer): TCreditTransferPaymentInformation;
    function GetPmtInfCount: Integer;
  public
    constructor Create;

    property Schema: String read GetSchema write fSchema;

    property GrpHdrMsgId: String read fGrpHdrMsgId write fGrpHdrMsgId;
    property GrpHdrCreDtTm: TDateTime read fGrpHdrCreDtTm write fGrpHdrCreDtTm;
    property GrpHdrNbOfTxs: Integer read GetGrpHdrNbOfTxs;
    property GrpHdrInitgPtyName: String read fGrpHdrInitgPtyName write SetGrpHdrInitgPtyName;

    procedure AppendPmtInfEntry(const instruction: TCreditTransferPaymentInformation);
    property PmtInfEntry[const i: Integer]: TCreditTransferPaymentInformation read GetPmtInfEntry;
    property PmtInfCount: Integer read GetPmtInfCount;

    function Validate: TStringList;
    procedure SaveToStream(const stream: TStream);
    procedure SaveToDisk(const FileName: String);
  end;

implementation

// TCreditTransferTransactionInformation

constructor TCreditTransferTransactionInformation.Create;
begin
  inherited Create;
  fPmtIdEndToEndId := END_TO_END_ID_NOTPROVIDED;
  fInstdAmtCcy     := CCY_EUR;
  fCdtrAgt         := TFinancialInstitution.Create;
  fCdtrAcct        := TAccountIdentification.Create;
end;

procedure TCreditTransferTransactionInformation.SetCdtrNm(const str: String);
begin
  fCdtrNm := SEPACleanString(str);
end;

procedure TCreditTransferTransactionInformation.SetRmtInfUstrd(const str: String);
begin
  fRmtInfUstrd := SEPACleanString(str);
end;

function TCreditTransferTransactionInformation.Validate(const schema: String): TStringList;
begin
  Result := TStringList.Create;

  // check for empty fields

  if PmtIdEndToEndId = '' then
    Result.Append(EMPTY_END_TO_END_ID);

  if InstdAmtCcy = '' then
    Result.Append(EMPTY_INSTD_AMT_CCY);

  if CdtrNm = '' then
    Result.Append(EMPTY_CDTR_NM);

  if RmtInfUstrd = '' then
    Result.Append(EMPTY_RMT_INF_USTRD);

  // check for invalid fields

  if not SEPACheckString(PmtIdEndToEndId, END_TO_END_ID_MAX_LEN) then
    Result.Append(Format(INVALID_END_TO_END_ID, [PmtIdEndToEndId]));

  if (InstdAmt <= 0.0) or not SEPACheckRounded(InstdAmt) then
    Result.Append(Format(INVALID_INSTD_AMT, [SEPAFormatAmount(InstdAmt, 4)]));

  if not SEPACheckString(CdtrNm, CDTR_NM_MAX_LEN) then
    Result.Append(Format(INVALID_CDTR_NM, [CdtrNm]));

  if not SEPACheckString(RmtInfUstrd, RMT_INF_USTRD_MAX_LEN) then
    Result.Append(Format(INVALID_RMT_INF_USTRD, [RmtInfUstrd]));

  // delegate validations where possible

  // note: for IBAN-only, according to the specification the creditor agent
  // has to be left out completely; not even NOTPROVIDED is allowed - yet, we
  // handle this the same way and just do not write this <CdtrAgt> block
  // to the file if no BIC is given (corresponds to NOTPROVIDED flag), see also
  // method SaveToStream
  Result.AddStrings(CdtrAgt.Validate(schema));

  Result.AddStrings(CdtrAcct.Validate(schema));

  // plausibility checks

  if (CdtrAgt.OthrID = FIN_INSTN_NOTPROVIDED) and not SEPAIsGermanIBAN(CdtrAcct.IBAN) then
    Result.Append(INVALID_IBAN_NOT_DE);
end;

procedure TCreditTransferTransactionInformation.SaveToStream(const stream: TStream; const schema: String);
begin
  SEPAWriteLine(stream, '<CdtTrfTxInf>');

  SEPAWriteLine(stream, '<PmtId><EndToEndId>'+SEPACleanString(PmtIdEndToEndId)+'</EndToEndId></PmtId>');
  SEPAWriteLine(stream, '<Amt><InstdAmt Ccy="'+SEPACleanString(InstdAmtCcy)+'">'+SEPAFormatAmount(InstdAmt)+'</InstdAmt></Amt>');

  if CdtrAgt.BIC <> '' then    // note: do not write <CdtrAgt> block to the file if IBAN-only
  begin                        //       is required, see also comment in method Validate
    SEPAWriteLine(stream, '<CdtrAgt>');
    CdtrAgt.SaveToStream(stream, schema);
    SEPAWriteLine(stream, '</CdtrAgt>');
  end;

  SEPAWriteLine(stream, '<Cdtr><Nm>'+SEPACleanString(CdtrNm, DBTR_NM_MAX_LEN)+'</Nm></Cdtr>');

  SEPAWriteLine(stream, '<CdtrAcct>');
  CdtrAcct.SaveToStream(stream, schema);
  SEPAWriteLine(stream, '</CdtrAcct>');

  SEPAWriteLine(stream, '<RmtInf><Ustrd>'+SEPACleanString(RmtInfUstrd, RMT_INF_USTRD_MAX_LEN)+'</Ustrd></RmtInf>');

  SEPAWriteLine(stream, '</CdtTrfTxInf>');
end;

// TCreditTransferPaymentInformation

constructor TCreditTransferPaymentInformation.Create;
begin
  inherited Create;
  fPmtInfId         := SEPAGenerateUUID;
  fPmtMtd           := PMT_MTD_CREDIT_TRANSFER;
  fPmtTpInfSvcLvlCd := SEPA;
  fChrgBr           := CHRG_BR_SLEV;
  fDbtrAcct         := TAccountIdentification.Create;
  fDbtrAgt          := TFinancialInstitution.Create;
end;

procedure TCreditTransferPaymentInformation.SetDbtrNm(const str: String);
begin
  fDbtrNm := SEPACleanString(str);
end;

function TCreditTransferPaymentInformation.GetCtrlSum: Currency;
var
  i: Integer;
begin
  Result := 0.0;
  for i := 0 to CdtTrfTxInfCount-1 do
    Result := Result + CdtTrfTxInfEntry[i].InstdAmt;
end;

procedure TCreditTransferPaymentInformation.AppendCdtTrfTxInfEntry(const transaction: TCreditTransferTransactionInformation);
var
  i: Integer;
begin
  i := Length(fCdtTrfTxInf);
  SetLength(fCdtTrfTxInf, i+1);
  fCdtTrfTxInf[i] := transaction;
end;

function TCreditTransferPaymentInformation.GetCdtTrfTxInfEntry(const i: Integer): TCreditTransferTransactionInformation;
begin
  Result := fCdtTrfTxInf[i];
end;

function TCreditTransferPaymentInformation.GetCdtTrfTxInfCount: Integer;
begin
  Result := Length(fCdtTrfTxInf);
end;

function TCreditTransferPaymentInformation.Validate(const schema: String): TStringList;
var
  i: Integer;
begin
  Result := TStringList.Create;

  // check for empty fields

  if PmtInfId = '' then
    Result.Append(EMPTY_PMT_INF_ID);

  if DbtrNm = '' then
    Result.Append(EMPTY_DBTR_NM);

  // check for invalid fields

  if not SEPACheckString(PmtInfId, ID_MAX_LEN) then
    Result.Append(Format(INVALID_PMT_INF_ID, [PmtInfId]));

  if PmtMtd <> PMT_MTD_CREDIT_TRANSFER then
    Result.Append(Format(INVALID_PMT_MTD, [PmtMtd]));

  if Trunc(ReqdExctnDt) < Today then
    Result.Append(Format(INVALID_REQD_EXCTN_DT, [DateToStr(ReqdExctnDt)]));

  if PmtTpInfSvcLvlCd <> SEPA then
    Result.Append(Format(INVALID_SVC_LVL_CD, [PmtTpInfSvcLvlCd]));

  if (PmtTpInfInstrPrty <> '') and (PmtTpInfInstrPrty <> INSTR_PRTY_NORM) and (PmtTpInfInstrPrty <> INSTR_PRTY_HIGH) then
    Result.Append(Format(INVALID_INSTR_PRTY, [PmtTpInfInstrPrty]));

  if ChrgBr <> CHRG_BR_SLEV then
    Result.Append(Format(INVALID_CHRG_BR, [ChrgBr]));

  if not SEPACheckString(DbtrNm, DBTR_NM_MAX_LEN) then
    Result.Append(Format(INVALID_DBTR_NM, [DbtrNm]));

  // delegate validations where possible

  Result.AddStrings(DbtrAcct.Validate(schema));
  Result.AddStrings(DbtrAgt.Validate(schema));

  for i := 0 to CdtTrfTxInfCount-1 do
    Result.AddStrings(CdtTrfTxInfEntry[i].Validate(schema));

  // plausibility checks

  if not SEPAIsGermanIBAN(DbtrAcct.IBAN) then
    Result.Append(INVALID_DBTR_ACCT_NOT_DE);

  // note: number of objects in DrctDbtTxInf is not checked - if empty, then this
  // object will be ignored by TCreditTransferInitiation; and TCreditTransferInitiation
  // ensures in its validation that it has some transactions
end;

procedure TCreditTransferPaymentInformation.SaveToStream(const stream: TStream; const schema: String);
var
  i: Integer;
begin
  SEPAWriteLine(stream, '<PmtInf>');

  SEPAWriteLine(stream, '<PmtInfId>'+SEPACleanString(PmtInfId)+'</PmtInfId>');
  SEPAWriteLine(stream, '<PmtMtd>'+SEPACleanString(PmtMtd)+'</PmtMtd>');
  SEPAWriteLine(stream, '<NbOfTxs>'+IntToStr(NbOfTxs)+'</NbOfTxs>');
  SEPAWriteLine(stream, '<CtrlSum>'+SEPAFormatAmount(CtrlSum)+'</CtrlSum>');

  SEPAWriteLine(stream, '<PmtTpInf>');
  if PmtTpInfInstrPrty <> '' then
    SEPAWriteLine(stream, '<InstrPrty>'+SEPACleanString(PmtTpInfInstrPrty)+'</InstrPrty>');
  SEPAWriteLine(stream, '<SvcLvl><Cd>'+SEPACleanString(PmtTpInfSvcLvlCd)+'</Cd></SvcLvl>');
  SEPAWriteLine(stream, '</PmtTpInf>');
  
  SEPAWriteLine(stream, '<ReqdExctnDt>'+SEPAFormatDate(ReqdExctnDt)+'</ReqdExctnDt>');
  SEPAWriteLine(stream, '<Dbtr><Nm>'+SEPACleanString(DbtrNm, DBTR_NM_MAX_LEN)+'</Nm></Dbtr>');

  SEPAWriteLine(stream, '<DbtrAcct>');
  DbtrAcct.SaveToStream(stream, schema);
  SEPAWriteLine(stream, '</DbtrAcct>');

  SEPAWriteLine(stream, '<DbtrAgt>');
  DbtrAgt.SaveToStream(stream, schema);
  SEPAWriteLine(stream, '</DbtrAgt>');

  SEPAWriteLine(stream, '<ChrgBr>'+SEPACleanString(ChrgBr)+'</ChrgBr>');

  for i := 0 to CdtTrfTxInfCount-1 do
    CdtTrfTxInfEntry[i].SaveToStream(stream, schema);

  SEPAWriteLine(stream, '</PmtInf>');
end;

// TCreditTransferInitiation

constructor TCreditTransferInitiation.Create;
begin
  inherited Create;
  fSchema        := ''; // empty = auto-select
  fGrpHdrMsgId   := SEPAGenerateUUID;
  fGrpHdrCreDtTm := Now;
end;

function TCreditTransferInitiation.GetSchema: String;
begin
  Result := fSchema;

  // Default schema:
  // - always choose pain.001.003.03 after February 1st, 2014
  //   (it is valid since November 4th, 2013 - but it seems several banks don't
  //    accept this new format for now...)
  // - otherwise, use pain.001.002.03

  if (Result = '') then
  begin
    if (Now > USE_SPEC_2DOT7) then
      Result := SCHEMA_PAIN_001_003_03
    else
      Result := SCHEMA_PAIN_001_002_03;
  end;
end;

procedure TCreditTransferInitiation.SetGrpHdrInitgPtyName(const str: String);
begin
  fGrpHdrInitgPtyName := SEPACleanString(str);
end;

function TCreditTransferInitiation.GetGrpHdrNbOfTxs: Integer;
var
  i: Integer;
begin
  Result := 0;
  for i := 0 to PmtInfCount-1 do
    Inc(Result, PmtInfEntry[i].NbOfTxs);
end;

procedure TCreditTransferInitiation.AppendPmtInfEntry(const instruction: TCreditTransferPaymentInformation);
var
  i: Integer;
begin
  i := Length(fPmtInf);
  SetLength(fPmtInf, i+1);
  fPmtInf[i] := instruction;
end;

function TCreditTransferInitiation.GetPmtInfEntry(const i: Integer): TCreditTransferPaymentInformation;
begin
  Result := fPmtInf[i];
end;

function TCreditTransferInitiation.GetPmtInfCount: Integer;
begin
  Result := Length(fPmtInf);   
end;

function TCreditTransferInitiation.Validate: TStringList;
var
  i: Integer;
begin
  Result := TStringList.Create;

  // check ISO schema

  if (Schema <> SCHEMA_PAIN_001_002_03) and (Schema <> SCHEMA_PAIN_001_003_03) then
    Result.Append(Format(UNKNOWN_SCHEMA, [Schema]));

  // check for empty fields

  if GrpHdrMsgId = '' then
    Result.Append(EMPTY_GRP_HDR_MSG_ID);

  if GrpHdrInitgPtyName = '' then
    Result.Append(EMPTY_INITG_PTY_NAME);

  // check for invalid fields

  if not SEPACheckString(GrpHdrMsgId, ID_MAX_LEN) then
    Result.Append(Format(INVALID_GRP_HDR_MSG_ID, [GrpHdrMsgId]));

  if not SEPACheckString(GrpHdrInitgPtyName, INITG_PTY_NAME_MAX_LEN) then
    Result.Append(Format(INVALID_INITG_PTY_NAME, [GrpHdrInitgPtyName]));

  // delegate validations where possible

  for i := 0 to PmtInfCount-1 do
    Result.AddStrings(PmtInfEntry[i].Validate(Schema));

  // plausibility checks

  if GrpHdrNbOfTxs = 0 then
    Result.Append(INVALID_NB_OF_TXS);
end;

procedure TCreditTransferInitiation.SaveToStream(const stream: TStream);
var
  i: Integer;
begin
  SEPAWriteLine(stream, '<?xml version="1.0" encoding="UTF-8"?>');
  SEPAWriteLine(stream, '<Document xmlns="urn:iso:std:iso:20022:tech:xsd:'+Schema+'"'+
                    ' xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"'+
                    ' xsi:schemaLocation="urn:iso:std:iso:20022:tech:xsd:'+Schema+' '+Schema+'.xsd">');
  SEPAWriteLine(stream, '<CstmrCdtTrfInitn>');

  SEPAWriteLine(stream, '<GrpHdr>');
  SEPAWriteLine(stream, '<MsgId>'+SEPACleanString(GrpHdrMsgId)+'</MsgId>');
  SEPAWriteLine(stream, '<CreDtTm>'+SEPAFormatDateTime(GrpHdrCreDtTm)+'</CreDtTm>');
  SEPAWriteLine(stream, '<NbOfTxs>'+IntToStr(GrpHdrNbOfTxs)+'</NbOfTxs>');
  SEPAWriteLine(stream, '<InitgPty><Nm>'+SEPACleanString(GrpHdrInitgPtyName, INITG_PTY_NAME_MAX_LEN)+'</Nm></InitgPty>');
  SEPAWriteLine(stream, '</GrpHdr>');

  for i := 0 to PmtInfCount-1 do
    if PmtInfEntry[i].NbOfTxs > 0 then
      PmtInfEntry[i].SaveToStream(stream, Schema);

  SEPAWriteLine(stream, '</CstmrCdtTrfInitn>');
  SEPAWriteLine(stream, '</Document>');
end;

procedure TCreditTransferInitiation.SaveToDisk(const FileName: String);
var
  stream: TMemoryStream;
begin
  stream := TMemoryStream.Create;
  try
    SaveToStream(stream);
    stream.SaveToFile(FileName);
  finally
    stream.Free;
  end;
end;

end.
