program Test_DLL;

// Make sure that the Clipper2 DLLS are in either
// the OS Path or in the application's folder.

{$APPTYPE CONSOLE}
{$R *.res}

uses
  Windows,
  Math,
  ShellApi,
  SysUtils,
  Clipper in '..\..\Delphi\Clipper2Lib\Clipper.pas',
  Clipper.Core in '..\..\Delphi\Clipper2Lib\Clipper.Core.pas',
  Clipper.Engine in '..\..\Delphi\Clipper2Lib\Clipper.Engine.pas',
  Clipper.SVG in '..\..\Delphi\Utils\Clipper.SVG.pas',
  Colors in '..\..\Delphi\Utils\Colors.pas',
  Timer in '..\..\Delphi\Utils\Timer.pas';

type
  CInt64arr   = array[0..$FFFF] of Int64;
  CPath64     = ^CInt64arr;
  CPaths64    = ^CInt64arr;
  CPolyPath64 = ^CInt64arr;
  CPolytree64 = ^CInt64arr;

  CDblarr     = array[0..$FFFF] of Double;
  CPathD      = ^CDblarr;
  CPathsD     = ^CDblarr;
  CPolyPathD  = ^CDblarr;
  CPolytreeD  = ^CDblarr;

const
{$IFDEF WIN64}
  CLIPPER2_DLL = 'Clipper2_64.dll';
{$ELSE}
  CLIPPER2_DLL = 'Clipper2_32.dll';
{$ENDIF}


////////////////////////////////////////////////////////
// Clipper2 DLL functions
////////////////////////////////////////////////////////

function Version(): PAnsiChar; cdecl;
  external CLIPPER2_DLL name 'Version';

procedure DisposeExportedCPaths64(var cps: CPaths64); cdecl;
  external CLIPPER2_DLL name 'DisposeExportedCPaths64';
procedure DisposeExportedCPathsD(var cp: CPathsD); cdecl;
  external CLIPPER2_DLL name 'DisposeExportedCPathsD';
procedure DisposeExportedCPolyTree64(var cpt: CPolyTree64); cdecl;
  external CLIPPER2_DLL name 'DisposeExportedCPolyTree64';
procedure DisposeExportedCPolyTreeD(var cpt: CPolyTreeD); cdecl;
  external CLIPPER2_DLL name 'DisposeExportedCPolyTreeD';

function BooleanOp64(cliptype: UInt8; fillrule: UInt8;
  const subjects: CPaths64; const subjects_open: CPaths64;
  const clips: CPaths64; out solution: CPaths64;
  out solution_open: CPaths64;
  preserve_collinear: boolean = true;
  reverse_solution: boolean = false): integer;  cdecl;
  external CLIPPER2_DLL name 'BooleanOp64';
function BooleanOp_PolyTree64(cliptype: UInt8; fillrule: UInt8;
  const subjects: CPaths64; const subjects_open: CPaths64;
  const clips: CPaths64; out solution: CPolyTree64;
  out solution_open: CPaths64;
  preserve_collinear: boolean = true;
  reverse_solution: boolean = false): integer; cdecl;
  external CLIPPER2_DLL name 'BooleanOp_PolyTree64';

function BooleanOpD(cliptype: UInt8; fillrule: UInt8;
  const subjects: CPathsD; const subjects_open: CPathsD;
  const clips: CPathsD; out solution: CPathsD; out solution_open: CPathsD;
  precision: integer = 2;
  preserve_collinear: boolean = true;
  reverse_solution: boolean = false): integer; cdecl;
  external CLIPPER2_DLL name 'BooleanOpD';
function BooleanOp_PolyTreeD(cliptype: UInt8; fillrule: UInt8;
  const subjects: CPathsD; const subjects_open: CPathsD;
  const clips: CPathsD; out solution: CPolyTreeD; out solution_open: CPathsD;
  precision: integer = 2;
  preserve_collinear: boolean = true;
  reverse_solution: boolean = false): integer; cdecl;
  external CLIPPER2_DLL name 'BooleanOp_PolyTreeD';
function InflatePaths64(const paths: CPaths64;
  delta: double; jointype, endtype: UInt8; miter_limit: double = 2.0;
  arc_tolerance: double = 0.0;
  reverse_solution: Boolean = false): CPaths64; cdecl;
  external CLIPPER2_DLL name 'InflatePaths64';
function InflatePathsD(const paths: CPathsD;
  delta: double; jointype, endtype: UInt8; precision: integer = 2;
  miter_limit: double = 2.0; arc_tolerance: double = 0.0;
  reverse_solution: Boolean = false): CPathsD; cdecl;
  external CLIPPER2_DLL name 'InflatePathsD';

function RectClip64(const rect: TRect64; const paths: CPaths64;
  convexOnly: Boolean = false): CPaths64; cdecl;
  external CLIPPER2_DLL name 'RectClip64';
function RectClipD(const rect: TRectD; const paths: CPathsD;
  precision: integer = 2; convexOnly: Boolean = false): CPathsD; cdecl;
  external CLIPPER2_DLL name 'RectClipD';
function RectClipLines64(const rect: TRect64;
  const paths: CPaths64): CPaths64; cdecl;
  external CLIPPER2_DLL name 'RectClipLines64';
function RectClipLinesD(const rect: TRectD;
  const paths: CPathsD; precision: integer = 2): CPathsD; cdecl;
  external CLIPPER2_DLL name 'RectClipLinesD';

const
  Intersection = 1; Union = 2; Difference =3; Xor_ = 4;
  EvenOdd = 0; NonZero = 1; Positive = 2; Negative = 3;
  magic_64 = 64; magic_D = 68;

////////////////////////////////////////////////////////
// functions related to Clipper2 DLL structures
////////////////////////////////////////////////////////

procedure DisposeLocalCPaths64(cp: CPaths64);
begin
  FreeMem(cp);
end;

procedure DisposeLocalCPathsD(cp: CPathsD);
begin
  FreeMem(cp);
end;

////////////////////////////////////////////////////////
// path format conversion functions
////////////////////////////////////////////////////////

function CreateCPaths64(const pp: TPaths64): CPaths64;
var
  i,j, len, len2: integer;
  v: PInt64;
begin
  len := Length(pp);
  len2 := 2;
  for i := 0 to len -1 do
    if Length(pp[i]) > 0 then
      inc(len2, Length(pp[i]) *2 + 2);
  GetMem(Result, len2 * sizeof(Int64));
  Result[0] := 0;
  Result[1] := len;
  v := @Result[2];
  for i := 0 to len -1 do
  begin
    len2 := Length(pp[i]);
    if len2 = 0 then continue;
    v^ := len2; inc(v);
    v^ := 0; inc(v);
    for j := 0 to len2 -1 do
    begin
      v^ := pp[i][j].X; inc(v);
      v^ := pp[i][j].Y; inc(v);
    end;
  end;
end;

function CreateCPathsD(const pp: TPathsD): CPathsD;
var
  i,j, len, len2: integer;
  v: PDouble;
begin
  len := Length(pp);
  len2 := 2;
  for i := 0 to len -1 do
    if Length(pp[i]) > 0 then
      inc(len2, Length(pp[i]) *2 + 2);
  GetMem(Result, len2 * sizeof(double));
  Result[0] := 0;
  Result[1] := len;
  v := @Result[2];
  for i := 0 to len -1 do
  begin
    len2 := Length(pp[i]);
    if len2 = 0 then continue;
    v^ := len2; inc(v);
    v^ := 0; inc(v);
    for j := 0 to len2 -1 do
    begin
      v^ := pp[i][j].X; inc(v);
      v^ := pp[i][j].Y; inc(v);
    end;
  end;
end;

function ConvertToTPaths64(cp: CPaths64): TPaths64;
var
  i, j, len, len2: integer;
  v: PInt64;
begin
  Result := nil;
  v := PInt64(cp);
  if v^ <> 0 then Exit; inc(v);
  len := v^; inc(v);
  SetLength(Result, len);
  for i := 0 to len -1 do
  begin
    len2 := v^; inc(v, 2);
    SetLength(Result[i], len2);
    for j := 0 to len2 -1 do
    begin
      Result[i][j].X := v^; inc(v);
      Result[i][j].Y := v^; inc(v);
    end;
  end;
end;

function ConvertToTPathsD(cp: CPathsD): TPathsD;
var
  i, j, len, len2: integer;
  v: PDouble;
begin
  Result := nil;
  if cp[0] <> 0 then Exit;
  len := Round(cp[1]);
  SetLength(Result, len);
  v := @cp[2];
  for i := 0 to len -1 do
  begin
    len2 := Round(v^); inc(v, 2);
    SetLength(Result[i], len2);
    for j := 0 to len2 -1 do
    begin
      Result[i][j].X := v^; inc(v);
      Result[i][j].Y := v^; inc(v);
    end;
  end;
end;

function GetPolyPath64ArrayLen(const pp: TPolyPath64): integer;
var
  i: integer;
begin
  Result := 4; // magic + is_hole + child_count + poly_length
  inc(Result, Length(pp.Polygon) * 2);
  for i := 0 to pp.Count -1 do
    Inc(Result, GetPolyPath64ArrayLen(pp.Child[i]));
end;

procedure GetPolytreeCountAndCStorageSize(const tree: TPolyTree64;
  out cnt: integer; out arrayLen: integer);
begin
  cnt := tree.Count; // nb: top level count only
  arrayLen := GetPolyPath64ArrayLen(tree);
end;

procedure CreateCPolyPathD(const pp: TPolyPath64;
  var v: PDouble; scale: double);
var
  i, len: integer;
begin
  v^ := magic_64; inc(v);
  if pp.IsHole then
    v^ := 1 else
    v^ := 0;
  inc(v);
  v^ := pp.Count; inc(v);
  len := Length(pp.Polygon);
  v^ := len; inc(v);
  for i := 0 to len -1 do
  begin
    v^ := pp.Polygon[i].x * scale;
    v^ := pp.Polygon[i].y * scale;
  end;
  for i := 0 to pp.Count -1 do
    CreateCPolyPathD(pp.Child[i], v, scale);
end;


function CreateCPolyTreeD(const tree: TPolyTree64; scale: double): CPolyTreeD;
var
  i, cnt, arrayLen: integer;
  v: PDouble;
begin
  Result := nil;
  GetPolytreeCountAndCStorageSize(tree, cnt, arrayLen);
  if cnt = 0 then Exit;
  // allocate storage
  GetMem(Result, arrayLen * SizeOf(double));

  v := PDouble(Result);
  v^ := magic_64; inc(v);
  v^ := 0; inc(v);
  v^ := tree.Count; inc(v);
  v^ := 0;  inc(v);
  for i := 0 to tree.Count - 1 do
    CreateCPolyPathD(tree.Child[i], v, scale);
end;

function CreatePolyPath64FromCPolyPath(var v: PInt64; owner: TPolyPath64): Boolean;
var
  i, magic, childCount, len: integer;
  path: TPath64;
  newOwner: TPolyPath64;
begin
  Result := false;
  magic := v^; inc(v, 2);
  childCount := v^; inc(v);
  len := v^; inc(v);
  if (magic <> magic_64) or (len = 0) then Exit;
  SetLength(path, len);
  for i := 0 to len -1 do
  begin
    path[i].X := v^; inc(v);
    path[i].Y := v^; inc(v);
  end;
  newOwner := TPolyPath64(owner.AddChild(path));
  for i := 0 to childCount -1 do
    if not CreatePolyPath64FromCPolyPath(v, newOwner) then Exit;
  Result := true;
end;

function BuildPolyTree64FromCPolyTree(tree: CPolyTree64; outTree: TPolyTree64): Boolean;
var
  v: PInt64;
  i, magic, childCount, len: integer;
begin
  Result := false;
  outTree.Clear();
  v := PInt64(tree);
  magic := v^; inc(v, 2);
  childCount := v^; inc(v);
  len := v^; inc(v);
  if (magic <> magic_64) or (len > 0) then Exit;
  for i := 0 to childCount -1 do
    if not CreatePolyPath64FromCPolyPath(v, outTree) then Exit;
  Result := true;
end;

function CreatePolyPathDFromCPolyPath(var v: PDouble; owner: TPolyPathD): Boolean;
var
  i, magic, childCount, len: integer;
  path: TPathD;
  newOwner: TPolyPathD;
begin
  Result := false;
  magic := Round(v^); inc(v, 2);
  childCount := Round(v^); inc(v);
  len := Round(v^); inc(v);
  if (magic <> magic_64) or (len = 0) then Exit;
  SetLength(path, len);
  for i := 0 to len -1 do
  begin
    path[i].X := v^; inc(v);
    path[i].Y := v^; inc(v);
  end;
  newOwner := TPolyPathD(owner.AddChild(path));
  for i := 0 to childCount -1 do
    if not CreatePolyPathDFromCPolyPath(v, newOwner) then Exit;
  Result := true;
end;

function BuildPolyTreeDFromCPolyTree(tree: CPolyTreeD; outTree: TPolyTreeD): Boolean;
var
  v: PDouble;
  i, magic, childCount, len: integer;
begin
  Result := false;
  outTree.Clear();
  v := PDouble(tree);
  magic := Round(v^); inc(v, 2);
  childCount := Round(v^); inc(v);
  len := Round(v^); inc(v);
  if (magic <> magic_64) or (len > 0) then Exit;
  for i := 0 to childCount -1 do
    if not CreatePolyPathDFromCPolyPath(v, outTree) then Exit;
  Result := true;
end;

////////////////////////////////////////////////////////
// miscellaneous functions
////////////////////////////////////////////////////////

function MakePath64(vals: array of Int64): TPath64;
var
  i, len: integer;
begin
  len := Length(vals) div 2;
  SetLength(Result, len);
  for i := 0 to len -1 do
  begin
    Result[i].X := vals[i*2];
    Result[i].Y := vals[i*2 +1];
  end;
end;

function MakePathD(vals: array of double): TPathD;
var
  i, len: integer;
begin
  len := Length(vals) div 2;
  SetLength(Result, len);
  for i := 0 to len -1 do
  begin
    Result[i].X := vals[i*2];
    Result[i].Y := vals[i*2 +1];
  end;
end;

function MakeRandomPath(maxWidth, maxHeight, count: Integer;
  margin: Integer = 10): TPath64;
var
  i: Integer;
begin
  setlength(Result, count);
  for i := 0 to count -1 do with Result[i] do
  begin
    X := Random(maxWidth - 2 * margin) + margin;
    Y := Random(maxHeight - 2 * margin) + margin;
  end;
end;

function MakeRandomPathD(maxWidth, maxHeight, count: Integer;
  margin: Integer = 10): TPathD;
var
  i: Integer;
begin
  setlength(Result, count);
  for i := 0 to count -1 do with Result[i] do
  begin
    X := Random(maxWidth - 2 * margin) + margin;
    Y := Random(maxHeight - 2 * margin) + margin;
  end;
end;

procedure ShowSvgImage(const svgFilename: string);
begin
  ShellExecute(0, 'open',PChar(svgFilename), nil, nil, SW_SHOW);
end;

const
  displayWidth = 600;
  displayHeight = 400;

procedure DisplaySVG(const sub, subo, clp, sol, solo: TPathsD;
  const svgName: string; width: integer = displayWidth;
  height: integer = displayHeight); overload;
var
  svg: TSvgWriter;
begin
  svg := TSvgWriter.Create(frNonZero);
  try
    AddSubject(svg, sub);
    AddOpenSubject(svg, subo);
    AddClip(svg, clp);
    AddSolution(svg, sol);
    AddOpenSolution(svg, solo);
    SaveSvg(svg, svgName, width, height);
    ShowSvgImage(svgName);
  finally
    svg.Free;
  end;
end;

procedure DisplaySVG(const sub, subo, clp, sol, solo: TPaths64;
  const svgName: string; width: integer = displayWidth;
  height: integer = displayHeight); overload;
var
  svg: TSvgWriter;
begin
  svg := TSvgWriter.Create(frNonZero);
  try
    AddSubject(svg, sub);
    AddOpenSubject(svg, subo);
    AddClip(svg, clp);

    AddSolution(svg, sol);
    AddOpenSolution(svg, solo);
    SaveSvg(svg, svgName, width, height);
    ShowSvgImage(svgName);
  finally
    svg.Free;
  end;
end;

////////////////////////////////////////////////////////
// test procedures
////////////////////////////////////////////////////////

procedure Test_Version();
begin
  Write(#10'Clipper2 DLL version: ');
  WriteLn(Version);
end;

procedure Test_BooleanOp64(edgeCnt: integer);
var
  sub, clp: TPaths64;
  csub_local, cclp_local: CPaths64;
  csol_extern, csolo_extern: CPaths64;
begin
    // setup
    csolo_extern := nil;
    WriteLn(#10'Testing BooleanOp64');
    SetLength(sub, 1);
    sub[0] := MakeRandomPath(displayWidth, displayHeight, edgeCnt);
    SetLength(clp, 1);
    clp[0] := MakeRandomPath(displayWidth, displayHeight, edgeCnt);
    // convert paths into DLL structures (will require local clean up)
    csub_local := CreateCPaths64(sub);
    cclp_local := CreateCPaths64(clp);

    // do the DLL operation
    BooleanOp64(Intersection, NonZero,
      csub_local, nil, cclp_local,
      csol_extern, csolo_extern);

    DisplaySVG(sub, nil, clp,
      ConvertToTPaths64(csol_extern), nil, 'BooleanOp64.svg');

    // clean up
    DisposeLocalCPaths64(csub_local);
    DisposeLocalCPaths64(cclp_local);
    DisposeExportedCPaths64(csol_extern);
    DisposeExportedCPaths64(csolo_extern);
end;

procedure Test_BooleanOpD(edgeCnt: integer);
var
  sub, clp: TPathsD;
  csub_local, cclp_local: CPathsD;
  csol_extern, csolo_extern: CPathsD;
begin
    // setup
    csolo_extern := nil;
    WriteLn(#10'Testing BooleanOpD');
    SetLength(sub, 1);
    sub[0] := MakeRandomPathD(displayWidth, displayHeight, edgeCnt);
    SetLength(clp, 1);
    clp[0] := MakeRandomPathD(displayWidth, displayHeight, edgeCnt);
    // convert paths into DLL structures (will require local clean up)
    csub_local := CreateCPathsD(sub);
    cclp_local := CreateCPathsD(clp);

    // do the DLL operation
    BooleanOpD(Uint8(TClipType.ctIntersection),
      Uint8(TFillRule.frNonZero),
      csub_local, nil, cclp_local,
      csol_extern, csolo_extern);

    // optionally display result on the console
    //WriteCPaths64(csol_extern);

    DisplaySVG(sub, nil, clp,
      ConvertToTPathsD(csol_extern), nil, 'BooleanOpD.svg');

    DisposeLocalCPathsD(csub_local);
    DisposeLocalCPathsD(cclp_local);
    DisposeExportedCPathsD(csol_extern);
    DisposeExportedCPathsD(csolo_extern);
end;

procedure Test_BooleanOp_Polytree64(edgeCnt: integer);
var
  sub, clp, sol: TPaths64;
  csub_local, cclp_local: CPaths64;
  csol_extern: CPolyTree64;
  tree: TPolyTree64;
  csol_open_extern: CPaths64;
begin
    // setup
    WriteLn(#10'Testing BooleanOp_PolyTree64');
    SetLength(sub, 1);
    sub[0] := MakeRandomPath(displayWidth, displayHeight, edgeCnt);
    SetLength(clp, 1);
    clp[0] := MakeRandomPath(displayWidth, displayHeight, edgeCnt);
    // convert paths into DLL structures (will require local clean up)
    csub_local := CreateCPaths64(sub);
    cclp_local := CreateCPaths64(clp);

    // do the DLL operation
    BooleanOp_PolyTree64(Intersection, NonZero,
      csub_local, nil, cclp_local, csol_extern, csol_open_extern);

    tree := TPolyTree64.Create;
    try
      BuildPolyTree64FromCPolyTree(csol_extern, tree);
      sol := PolyTreeToPaths64(tree);
    finally
      tree.Free;
    end;
    DisposeExportedCPolyTree64(csol_extern);
    DisposeExportedCPaths64(csol_open_extern);

    DisposeLocalCPaths64(csub_local);
    DisposeLocalCPaths64(cclp_local);

    // finally, display and clean up
    DisplaySVG(sub, nil, clp, sol, nil, 'BooleanOp_PolyTree64.svg');
end;

procedure Test_BooleanOp_PolytreeD(edgeCnt: integer);
var
  sub, clp, sol: TPathsD;
  csub_local, cclp_local: CPathsD;
  csol_extern: CPolyTreeD;
  tree: TPolyTreeD;
  csol_open_extern: CPathsD;
begin
    // setup
    WriteLn(#10'Testing BooleanOp_PolyTreeD');
    SetLength(sub, 1);
    sub[0] := MakeRandomPathD(displayWidth, displayHeight, edgeCnt);
    SetLength(clp, 1);
    clp[0] := MakeRandomPathD(displayWidth, displayHeight, edgeCnt);
    // convert paths into DLL structures (will require local clean up)
    csub_local := CreateCPathsD(sub);
    cclp_local := CreateCPathsD(clp);

    // do the DLL operation
    BooleanOp_PolyTreeD(Intersection, NonZero,
      csub_local, nil, cclp_local, csol_extern, csol_open_extern);

    tree := TPolyTreeD.Create;
    try
      BuildPolyTreeDFromCPolyTree(csol_extern, tree);
      sol := PolyTreeToPathsD(tree);
    finally
      tree.Free;
    end;
    DisposeExportedCPolyTreeD(csol_extern);
    DisposeExportedCPathsD(csol_open_extern);

    DisposeLocalCPathsD(csub_local);
    DisposeLocalCPathsD(cclp_local);

    // finally, display and clean up
    DisplaySVG(sub, nil, clp, sol, nil, 'BooleanOp_PolyTreeD.svg');
end;

procedure Test_InflatePathsD(edgeCnt: integer; delta: double);
var
  sub: TPathsD;
  csub_local: CPathsD;
  csol_extern: CPathsD;
  csolo_extern: CPathsD;
begin
    // setup
    WriteLn(#10'Testing InflatePaths64');
    SetLength(sub, 1);
    sub[0] := MakeRandomPathD(displayWidth, displayHeight, edgeCnt);
    // convert path into required DLL structure (also requires local clean up)
    csub_local := CreateCPathsD(sub);

    // and because offsetting self-intersecting paths is unpredictable
    // we must remove self-intersection via a union operation
    BooleanOpD(Uint8(TClipType.ctUnion),
      Uint8(TFillRule.frNonZero), csub_local, nil, nil,
      csol_extern, csolo_extern);

    // now do the DLL operation
    csol_extern := InflatePathsD(csol_extern, delta,
      UInt8(TJoinType.jtRound), UInt8(TEndType.etPolygon), 2, 4);

    // optionally display result on the console
    //WriteCPaths64(csol_extern);

    DisplaySVG(sub, nil, nil,
      ConvertToTPathsD(csol_extern), nil, 'InflatePathsD.svg');

    DisposeLocalCPathsD(csub_local);
    DisposeExportedCPathsD(csol_extern);
    DisposeExportedCPathsD(csolo_extern);
end;

procedure Test_RectClipD(shapeCount: integer);
var
  i, rec_margin: Integer;
  sub, clp, sol1, sol2: TPathsD;
  csub_local: CPathsD;
  csol_extern: CPathsD;
  scaleRnd, maxOffX, maxOffY: Double;
  rec: TRectD;
  shapes: array [0..3] of TPathD;
const
  w = 300;
  h = 300;
begin
    // four simple concave polygons
    shapes[0] := MakePathD([20,20, 20,0, 40,0, 40,20, 60,20, 60,40,
      40,40, 40,60, 20,60, 20,40, 0,40, 0,20]);
    shapes[1] := MakePathD([0,0, 60,0, 60,20, 20,20, 20,40, 60,40,
      60,60, 0,60]);
    shapes[2] := MakePathD([0,0, 20,0, 20,20, 40,20, 40,0, 60,0,
      60,60, 40,60, 40,40, 20,40, 20,60, 0,60]);
    shapes[3] := MakePathD([20,60, 20,20, 0,20, 0,0, 60,0, 60,20,
      40,20, 40,60]);

    // setup
    WriteLn(#10'Testing RectClip64:');

    rec_margin := Min(w,h) div 3;
    rec.Left := rec_margin;
    rec.Top := rec_margin;
    rec.Right := w - rec_margin;
    rec.Bottom := h -rec_margin;

    SetLength(sub, shapeCount);
    for i := 0 to shapeCount -1 do
    begin
      scaleRnd := (60 + Random(w div 4)) / 120;
      maxOffX := w - (scaleRnd * 60);
      maxOffY := h - (scaleRnd * 60);
      sub[i] := ScalePathD(shapes[Random(4)], scaleRnd);
      sub[i] := TranslatePath(sub[i],
        Random(Round(maxOffX)), Random(Round(maxOffY)));
    end;

    csub_local := CreateCPathsD(sub);
    csol_extern := RectClipD(rec, csub_local, 2, true);
    sol1 := ConvertToTPathsD(csol_extern);
    DisposeExportedCPathsD(csol_extern);

    // do the DLL operation again with ConvexOnly disabled
    csol_extern := RectClipD(rec, csub_local, 2, false);
    sol2 := ConvertToTPathsD(csol_extern);

    SetLength(clp, 1);
    clp[0] := rec.AsPath;

    DisplaySVG(sub, nil, clp, sol2, nil, 'RectClip64_3.svg', w,h);

    DisposeLocalCPathsD(csub_local);
    DisposeExportedCPathsD(csol_extern);
end;

procedure Test_RectClipLines64(edgeCnt: integer);
var
  sub, clp: TPaths64;
  csub_local: CPaths64;
  csolo_extern: CPaths64;
  rec: TRect64;
begin
    // setup
    WriteLn(#10'Testing RectClipLines64:');
    SetLength(sub, 1);

    sub[0] := MakeRandomPath(displayWidth, displayHeight, edgeCnt);
    csub_local := CreateCPaths64(sub);

    rec.Left := 80;
    rec.Top := 80;
    rec.Right := displayWidth - 80;
    rec.Bottom := displayHeight -80;

    // do the DLL operation
    csolo_extern := RectClipLines64(rec, csub_local);

    SetLength(clp, 1);
    clp[0] := rec.AsPath;

    DisplaySVG(nil, sub, clp, nil,
      ConvertToTPaths64(csolo_extern), 'RectClipLines64.svg');

    DisposeLocalCPaths64(csub_local);
    DisposeExportedCPaths64(csolo_extern);
end;

////////////////////////////////////////////////////////
// main entry here
////////////////////////////////////////////////////////

var
  s: string;
begin
  Randomize;
  Test_Version();
  Test_BooleanOp64(25);
  Test_BooleanOpD(25);
  Test_BooleanOp_Polytree64(15);
  Test_BooleanOp_PolytreeD(25);
  Test_InflatePathsD(20, -10); // edgeCount, offsetDist
  Test_RectClipD(15);
  Test_RectClipLines64(25);

  WriteLn(#10'Press Enter to quit.');
  ReadLn(s);
end.
