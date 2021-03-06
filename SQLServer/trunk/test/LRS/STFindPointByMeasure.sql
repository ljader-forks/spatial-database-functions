SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
GO

Print 'Testing [$(lrsowner)].[STFindPointByMeasure] ...';
GO

with data as (
select geometry::STGeomFromText('LINESTRING(-4 -4 0  1, 0  0 0  5.6, 10  0 0 15.61, 10 10 0 25.4)',28355) as linestring
)
select 'Original Linestring as backdrop for SSMS mapping' as locateType, [$(lrsowner)].[STFindPointByMeasure](linestring,null,0,3,2).STBuffer(1) as measureSegment from data as a
union all
select 'Null measure (-> NULL)' as locateType, [$(lrsowner)].[STFindPointByMeasure](linestring,null,0,3,2).STBuffer(1) as measureSegment from data as a
union all
select 'Measure = Before First SM -> NULL)' as locateType, [$(lrsowner)].[STFindPointByMeasure](linestring,0.1,0,3,2).STBuffer(2) as measureSegment from data as a
union all
select 'Measure = 1st Segment SP -> SM' as locateType, [$(lrsowner)].[STFindPointByMeasure](linestring,1,0,3,2).STBuffer(2) as measureSegment from data as a
union all
select 'Measure = 1st Segment EP -> EM' as locateType, [$(lrsowner)].[STFindPointByMeasure](linestring,5.6,0,3,2).STBuffer(2) as measureSegment from data as a
union all
select 'Measure = MidPoint 1st Segment -> NewM' as locateType, [$(lrsowner)].[STFindPointByMeasure](linestring,2.3,0,3,2).STBuffer(2) as measureSegment from data as a
union all
select 'Measure = 2nd Segment MP -> NewM' as locateType, [$(lrsowner)].[STFindPointByMeasure](linestring,10.0,0,3,2).STBuffer(2) as measureSegment from data as a
union all
select 'Measure = Last Segment Mid Point' as locateType, [$(lrsowner)].[STFindPointByMeasure](linestring,20.0,0,3,2).STBuffer(2) as measureSegment from data as a
union all
select 'Measure = Last Segment End Point' as locateType, [$(lrsowner)].[STFindPointByMeasure](linestring,25.4,0,3,2).STBuffer(2) as measureSegment from data as a
union all
select 'Measure = After Last Segment''s End Point Measure' as locateType, [$(lrsowner)].[STFindPointByMeasure](linestring,47.0,0,3,2).STBuffer(2) as measureSegment from data as a;
GO

with data as (
select geometry::STGeomFromText('LINESTRING(-4 -4 0  4, 0  0 0 2)',28355) as rlinestring
)
select 'Measure is middle First With Reversed Measures' as locateType, [$(lrsowner)].[STFindPointByMeasure](rlinestring,3.0,0,3,2).AsTextZM() as measureSegment from data as a;
GO

-- Now with offset
with data as (
select geometry::STGeomFromText('LINESTRING(-4 -4 0  1, 0  0 0  5.6, 10  0 0 15.61, 10 10 0 25.4)',28355) as linestring
)
select 'LineString' as locateType, linestring from data as a
union all
select 'Measure = First Segment Start Point' as locateType, [$(lrsowner)].[STFindPointByMeasure](linestring,1,-1.0,3,2).STBuffer(2) as measureSegment from data as a
union all
select 'Measure = First Segment End Point' as locateType, [$(lrsowner)].[STFindPointByMeasure](linestring,5.6,-1.0,3,2).STBuffer(2) as measureSegment from data as a
union all
select 'Measure is middle First Segment' as locateType, [$(lrsowner)].[STFindPointByMeasure](linestring,2.3,-1.0,3,2).STBuffer(2) as measureSegment from data as a
union all
select 'Measure = Second Segment Mid Point' as locateType, [$(lrsowner)].[STFindPointByMeasure](linestring,10.0,-1.0,3,2).STBuffer(2) as measureSegment from data as a
union all
select 'Measure = Last Segment Mid Point' as locateType, [$(lrsowner)].[STFindPointByMeasure](linestring,20.0,-1.0,3,2).STBuffer(2) as measureSegment from data as a
union all
select 'Measure = Last Segment End Point' as locateType, [$(lrsowner)].[STFindPointByMeasure](linestring,25.4,-1.0,3,2).STBuffer(2) as measureSegment from data as a;
GO

-- Measures plus left/right offsets

with data as (
select geometry::STGeomFromText('LINESTRING(-4 -4 0  1, 0  0 0  5.6, 10  0 0 15.61, 10 10 0 25.4)',28355) as linestring
)
select g.intValue as measure,
       o.IntValue as offset,
       [$(lrsowner)].[STFindPointByMeasure](linestring,g.IntValue,o.IntValue,3,2).STBuffer(0.5) as fPoint
  from data as a
       cross apply
       [$(owner)].[generate_series](a.lineString.STPointN(1).M, round(a.lineString.STPointN(a.linestring.STNumPoints()).M,0,1), 2 ) as g
       cross apply
       [$(owner)].[generate_series](-1,1,1) as o
union all
select g.intValue as measure,
       o.IntValue as offset,
       [$(lrsowner)].[STFindPointByMeasure](linestring, linestring.STPointN(g.IntValue).M, o.IntValue,3,2).STBuffer(0.5) as fPoint
  from data as a
       cross apply
       [$(owner)].[generate_series](1, a.lineString.STNumPoints(), 1 ) as g
       cross apply
       [$(owner)].[generate_series](-1,1,1) as o
union all
select null as measure, 
       null as offset,
       linestring.STBuffer(0.2)
  from data as a;
GO

-- Check that offset point disappears if offset > radius on correct side
with data as (
  select geometry::STGeomFromText('CIRCULARSTRING (3 6.325 NULL 0, 0 7 NULL 3.08, -3 6.325 NULL 6.15)',0) as linestring
 )
select 'C' as curve_type,  -1 as measure, 0 as offset, [$(cogoowner)].[STFindCircleFromArc](A.linestring).STBuffer(0.3) as geom from data as a
union all
select 'L' as curve_type,0 as measure,0 as offset,linestring from data 
union all
select 'M', 4.0, offset.IntValue, [$(lrsowner)].[STFindPointByMeasure](a.linestring,4.0,offset.IntValue,0,3,2).STBuffer(0.2) 
  from data as a
       cross apply 
       dbo.generate_series(-9,9,1) as offset;

-- Circular Arc / Measured Tests
with data as (
  select geometry::STGeomFromText('CIRCULARSTRING (3 6.325 NULL 0, 0 7 NULL 3.08, -3 6.325 NULL 6.15)',0) as linestring
  union all 
  select [$(lrsowner)].[STAddMeasure](
           geometry::STGeomFromText('COMPOUNDCURVE(CIRCULARSTRING (3 6.3246, 0 7, -3 6.3246),(-3 6.3246, 0 0, 3 6.3246))',0),
		   0.0,
           geometry::STGeomFromText('COMPOUNDCURVE(CIRCULARSTRING (3 6.3246, 0 7, -3 6.3246),(-3 6.3246, 0 0, 3 6.3246))',0).STLength(),
		   4,4) as linestring
)
select 'Centre' as curve_type,  -1 as measure, 0 as offset, [$(cogoowner)].[STFindCircleFromArc](A.linestring).STBuffer(0.3) from data as a
union all
select 'original' as curve_type,0 as measure,0 as offset,
       linestring as fPoint
  from data union all
select CAST(a.linestring.STGeometryType() as varchar(30)) as curve_type,
       g.intValue as measure,
       o.IntValue as offset,
       [$(lrsowner)].[STFindPointByMeasure](a.linestring,g.IntValue,o.IntValue,3,2).STBuffer(0.2) as fPoint
  from data as a
       cross apply
       [$(owner)].[generate_series](a.lineString.STPointN(1).M,
                               round(a.lineString.STPointN(a.linestring.STNumPoints()).M,0,1),
                               [$(lrsowner)].[STMeasureRange](a.linestring) / 4.0 ) as g
       cross apply
       [$(owner)].[generate_series](-1, 1, 1) as o
order by curve_type, measure;
GO

with data as (
  select geometry::STGeomFromText('COMPOUNDCURVE(CIRCULARSTRING (3 6.3246 -1 0, 0 7 -1 3.08, -3 6.3246 -1 6.15),(-3 6.3246 -1 6.15, 0 0 -2.0 10.1, 3 6.3246 -1.0 20.2))',0) as cLine
)
select CAST(measure.IntValue as numeric) as measure,
       CAST(o.IntValue as numeric) / 2.0 as offset,
       [$(lrsowner)].[STFindPointByMeasure](
          /* @p_linestring*/ a.cLine,
          /* @p_measure   */ CAST(measure.IntValue as numeric),
          /* @p_offset    */ CAST(o.IntValue as numeric),
          /* @p_round_xy  */   3,
          /* @p_round_zm  */   2
       ).STBuffer(0.3) as fPoint
  from data as a
       cross apply [$(owner)].[Generate_Series](a.cLine.STStartPoint().M,a.cLine.STEndPoint().M,1) as measure
       cross apply [$(owner)].[generate_series](-1,1,1) as o
union all
select null as ratio,
       null as offset,
       A.cLine.STBuffer(0.1)
  FROM data as a
GO

-- #############################################################
-- Customer Tests

with I124 as (
 select geometry::STGeomFromText('CompoundCurve (
CircularString (2172207.12090003490447998 256989.8612000048160553 NULL 11200, 2172337.52737651020288467 257437.9648682993138209 NULL 11671.4157, 2172663.83167292177677155 257771.62375517189502716 NULL 12142.83130000000528526),
 (2172663.83167292177677155 257771.62375517189502716 NULL 12142.83130000000528526, 2173053.90566198527812958 258011.32397928833961487 NULL 12600.66749999999592546),
CircularString (2173053.90566198527812958 258011.32397928833961487 NULL 12600.66749999999592546, 2173287.01136440876871347 258189.96358297357801348 NULL 12894.8702, 2173478.70718778669834137 258412.45647680759429932 NULL 13189.07289999999920838),
CircularString (2173478.70718778669834137 258412.45647680759429932 NULL 13189.07289999999920838, 2173748.77927610510960221 258973.8411394071590621 NULL 13814.706, 2173828.65654586255550385 259591.66902326047420502 NULL 14440.33909999999741558),
 (2173828.65654586255550385 259591.66902326047420502 NULL 14440.33909999999741558, 2173758.29399192333221436 261836.17986378073692322 NULL 16685.95260000000416767),
CircularString (2173758.29399192333221436 261836.17986378073692322 NULL 16685.95260000000416767, 2173725.78396705072373152 262165.54628049046732485 NULL 17017.1677, 2173649.53159222006797791 262487.60949401557445526 NULL 17348.38270000000193249),
 (2173649.53159222006797791 262487.60949401557445526 NULL 17348.38270000000193249, 2173560.78142566978931427 262776.41380821168422699 NULL 17650.51600000000325963),
CircularString (2173560.78142566978931427 262776.41380821168422699 NULL 17650.51600000000325963, 2173487.32788622565567493 263024.51879732898669317 NULL 17909.2736, 2173420.50443191826343536 263274.49106386303901672 NULL 18168.03109999999287538),
 (2173420.50443191826343536 263274.49106386303901672 NULL 18168.03109999999287538, 2173069.13725355267524719 264662.68272183835506439 NULL 19600, 2172750.15174546837806702 265922.93993593752384186 NULL 20900))',2274) as geom
)
SELECT [$(lrsowner)].[STFindPointByMeasure](
 a.geom, 12000, 499, 4, 4).AsTextZM() as Point_From_I124_With_Zero_MidPt_Measures
 FROM I124 as a
go
/*
POINT (2172869.5278 257306.3618 NULL 12000)
*/

with I124 as (
 select geometry::STGeomFromText('CompoundCurve (
CircularString (2172207.12090003490447998 256989.8612000048160553 NULL 11200, 2172337.52737651020288467 257437.9648682993138209 NULL 0, 2172663.83167292177677155 257771.62375517189502716 NULL 12142.83130000000528526),
 (2172663.83167292177677155 257771.62375517189502716 NULL 12142.83130000000528526, 2173053.90566198527812958 258011.32397928833961487 NULL 12600.66749999999592546),
CircularString (2173053.90566198527812958 258011.32397928833961487 NULL 12600.66749999999592546, 2173287.01136440876871347 258189.96358297357801348 NULL 0, 2173478.70718778669834137 258412.45647680759429932 NULL 13189.07289999999920838),
CircularString (2173478.70718778669834137 258412.45647680759429932 NULL 13189.07289999999920838, 2173748.77927610510960221 258973.8411394071590621 NULL 0, 2173828.65654586255550385 259591.66902326047420502 NULL 14440.33909999999741558),
 (2173828.65654586255550385 259591.66902326047420502 NULL 14440.33909999999741558, 2173758.29399192333221436 261836.17986378073692322 NULL 16685.95260000000416767),
CircularString (2173758.29399192333221436 261836.17986378073692322 NULL 16685.95260000000416767, 2173725.78396705072373152 262165.54628049046732485 NULL 0, 2173649.53159222006797791 262487.60949401557445526 NULL 17348.38270000000193249),
 (2173649.53159222006797791 262487.60949401557445526 NULL 17348.38270000000193249, 2173560.78142566978931427 262776.41380821168422699 NULL 17650.51600000000325963),
CircularString (2173560.78142566978931427 262776.41380821168422699 NULL 17650.51600000000325963, 2173487.32788622565567493 263024.51879732898669317 NULL 0, 2173420.50443191826343536 263274.49106386303901672 NULL 18168.03109999999287538),
 (2173420.50443191826343536 263274.49106386303901672 NULL 18168.03109999999287538, 2173069.13725355267524719 264662.68272183835506439 NULL 19600, 2172750.15174546837806702 265922.93993593752384186 NULL 20900))',2274) as geom
)
SELECT [$(lrsowner)].[STFindPointByMeasure](
 a.geom, 12000, 499, 4, 4).AsTextZM() as Point_From_I124_With_Calced_MidPt_Measures
 FROM I124 as a;
 GO

-- POINT (2172869.5278 257306.3618 NULL 12000)

-- ***********************************************************************************

-- ******
-- Test 1
with I124 as (
 select geometry::STGeomFromText('CompoundCurve (
CircularString (2172207.12090003490447998 256989.8612000048160553 NULL 11200, 2172337.52737651020288467 257437.9648682993138209 NULL 0, 2172663.83167292177677155 257771.62375517189502716 NULL 12142.83130000000528526),
 (2172663.83167292177677155 257771.62375517189502716 NULL 12142.83130000000528526, 2173053.90566198527812958 258011.32397928833961487 NULL 12600.66749999999592546),
CircularString (2173053.90566198527812958 258011.32397928833961487 NULL 12600.66749999999592546, 2173287.01136440876871347 258189.96358297357801348 NULL 0, 2173478.70718778669834137 258412.45647680759429932 NULL 13189.07289999999920838),
CircularString (2173478.70718778669834137 258412.45647680759429932 NULL 13189.07289999999920838, 2173748.77927610510960221 258973.8411394071590621 NULL 0, 2173828.65654586255550385 259591.66902326047420502 NULL 14440.33909999999741558),
 (2173828.65654586255550385 259591.66902326047420502 NULL 14440.33909999999741558, 2173758.29399192333221436 261836.17986378073692322 NULL 16685.95260000000416767),
CircularString (2173758.29399192333221436 261836.17986378073692322 NULL 16685.95260000000416767, 2173725.78396705072373152 262165.54628049046732485 NULL 0, 2173649.53159222006797791 262487.60949401557445526 NULL 17348.38270000000193249),
 (2173649.53159222006797791 262487.60949401557445526 NULL 17348.38270000000193249, 2173560.78142566978931427 262776.41380821168422699 NULL 17650.51600000000325963),
CircularString (2173560.78142566978931427 262776.41380821168422699 NULL 17650.51600000000325963, 2173487.32788622565567493 263024.51879732898669317 NULL 0, 2173420.50443191826343536 263274.49106386303901672 NULL 18168.03109999999287538),
 (2173420.50443191826343536 263274.49106386303901672 NULL 18168.03109999999287538, 2173069.13725355267524719 264662.68272183835506439 NULL 19600, 2172750.15174546837806702 265922.93993593752384186 NULL 20900))',2274) as geom
)
SELECT 0 as measure, A.geom from I124 as a
union all
SELECT along.IntValue, [$(lrsowner)].[STFindPointByMeasure](
           a.geom, 
           along.IntValue,
		   offset.IntValue, 
		   4, 4)
		   .STBuffer(50) as Point_From_I124_With_Calced_MidPt_Measures
 FROM I124 as a
      cross apply
      dbo.Generate_Series(
       a.geom.STStartPoint().M+1,
	   a.geom.STEndPoint().M-1,
	   100) as along
	   cross apply 
	   dbo.Generate_Series(-500,500,500) as offset;

-- ******
-- Test 2
with Ramp_H as (
select geometry::STGeomFromText('COMPOUNDCURVE ((2173251.19755045 260565.663264811 NULL 2000,2173324.62503405 260532.888690099 NULL 2080.4098),
          CIRCULARSTRING (2173324.62503405 260532.888690099 NULL 2080.4098,2173345.78352624 260520.72691965 NULL 0,2173364.04390489 260504.535902888 NULL 2129.3036),
          CIRCULARSTRING (2173364.04390489 260504.535902888 NULL 2129.3036,2173381.19882422 260470.679448103 NULL 0,2173378.16228123 260432.846523359 NULL 2206.1746),
                         (2173378.16228123 260432.846523359 NULL 2206.1746,2173355.55940427 260371.804622516 NULL 2271.2667,2173350.99754606 260362.115766078 NULL 2281.9758),
          CIRCULARSTRING (2173350.99754606 260362.115766078 NULL 2281.9758,2173336.7026266 260144.609642233 NULL 0,2173474.30695651 259975.558445781 NULL 2728.2803),
                         (2173474.30695651 259975.558445781 NULL 2728.2803,2173476.92754695 259974.081665367 NULL 2731.2883),
          CIRCULARSTRING (2173476.92754695 259974.081665367 NULL 2731.2883,2173644.89258743 259822.983578196 NULL 0,2173732.74541767 259614.837554961 NULL 3186.7865),
          CIRCULARSTRING (2173732.74541767 259614.837554961 NULL 3186.7865,2173749.05001496 259459.972709981 NULL 0,2173742.0037621 259304.411434516 NULL 3498.52))',2274) as geom
)
SELECT 0 as measure, A.geom from Ramp_H as a
union all
SELECT along.IntValue, [$(lrsowner)].[STFindPointByMeasure](
a.geom,
along.IntValue,
offset.IntValue,
4, 4)
.STBuffer(20) as Point_From_Ramp_H_With_Zero_MidPt_Measures
FROM Ramp_H as a
cross apply
dbo.Generate_Series(
a.geom.STStartPoint().M+1,
a.geom.STEndPoint().M-1,
20) as along
cross apply
dbo.Generate_Series(-500,500,500) as offset;

-- Test 3
-- ******
with Ramp_H1 as (
select geometry::STGeomFromText('COMPOUNDCURVE ((2173369.79254475 259887.575230554 NULL 2600,2173381.122467 259911.320734575 NULL 2626.3106),CIRCULARSTRING (2173381.122467 259911.320734575 NULL 2626.3106,2173433.84355779 259955.557426129 NULL 0,2173501.82006501 259944.806018785 NULL 2768.24))',2274) as geom
)
SELECT 0 as measure, A.geom from Ramp_H1 as a
union all
SELECT along.IntValue, [$(lrsowner)].[STFindPointByMeasure](
a.geom,
along.IntValue,
offset.IntValue,
4, 4)
.STBuffer(10) as Point_From_Ramp_H1_With_Zero_MidPt_Measures
FROM Ramp_H1 as a
cross apply
dbo.Generate_Series(
a.geom.STStartPoint().M+1,
a.geom.STEndPoint().M-1,
5) as along
cross apply
dbo.Generate_Series(-500,500,500) as offset;

-- ******
-- Test 4
with RFP1 as (
select geometry::STGeomFromText('COMPOUNDCURVE ((2172150.6845635027 258351.6130952388 NULL 7500, 2171796.8166267127 257562.7279690057 NULL 8364.6171999999933), 
CIRCULARSTRING (2171796.8166267127 257562.7279690057 NULL 8364.6171999999933, 2171785.1539784111 257183.20449278614 NULL 0, 2172044.2970194966 256905.68157368898 NULL 9143.7173000000039), 
(2172044.2970194966 256905.68157368898 NULL 9143.7173000000039, 2172405.6545540541 256740.52740873396 NULL 9541.0274000000063), 
CIRCULARSTRING (2172405.6545540541 256740.52740873396 NULL 9541.0274000000063, 2172647.6470565521 256579.20296130711 NULL 0, 2172826.9283746332 256350.1960671097 NULL 10125.168300000005), 
(2172826.9283746332 256350.1960671097 NULL 10125.168300000005, 2172922.0147634745 256178.15253089368 NULL 10321.740000000005))',2274) as geom
)
SELECT 0 as measure, A.geom from RFP1 as a
union all
SELECT along.IntValue, [$(lrsowner)].[STFindPointByMeasure](
a.geom,
along.IntValue,
offset.IntValue,
4, 4)
.STBuffer(20) as Point_From_RFP1_With_Zero_MidPt_Measures
FROM RFP1 as a
cross apply
dbo.Generate_Series(
a.geom.STStartPoint().M+1,
a.geom.STEndPoint().M-1,
20) as along
cross apply
dbo.Generate_Series(-500,500,500) as offset;

-- ******
-- Test 5
with RFP2 as (
select geometry::STGeomFromText('COMPOUNDCURVE ((2172689.5850816667 263297.43350273371 NULL 20000, 2172870.5653368235 263341.6981946826 NULL 20186.314400000003), 
CIRCULARSTRING (2172870.5653368235 263341.6981946826 NULL 20186.314400000003, 2172949.36071442 263374.02539862844 NULL 0, 2173015.1427358091 263428.122397691 NULL 20357.287800000006), 
(2173015.1427358091 263428.122397691 NULL 20357.287800000006, 2173091.9710562378 263513.43623405695 NULL 20472.096300000005), 
CIRCULARSTRING (2173091.9710562378 263513.43623405695 NULL 20472.096300000005, 2173234.6914302604 263621.66524513043 NULL 0, 2173407.26756607 263669.62461698055 NULL 20832.466700000004), 
(2173407.26756607 263669.62461698055 NULL 20832.466700000004, 2173737.8756920993 263696.85831338167 NULL 21164.1939), 
CIRCULARSTRING (2173737.8756920993 263696.85831338167 NULL 21164.1939, 2174060.2842410011 263742.02676398389 NULL 0, 2174375.4616589993 263823.57832141221 NULL 21815.659499999994), 
(2174375.4616589993 263823.57832141221 NULL 21815.659499999994, 2174455.1104600877 263849.10933355987 NULL 21899.300000000003))',2274) as geom
)
SELECT 0 as measure, A.geom from RFP2 as a
union all
SELECT along.IntValue, [$(lrsowner)].[STFindPointByMeasure](
a.geom,
along.IntValue,
offset.IntValue,
4, 4)
.STBuffer(20) as Point_From_RFP2_With_Zero_MidPt_Measures
FROM RFP2 as a
cross apply
dbo.Generate_Series(
a.geom.STStartPoint().M+1,
a.geom.STEndPoint().M-1,
20) as along
cross apply
dbo.Generate_Series(-500,500,500) as offset;

use DEVDB
go

with Ramp_H as (
select geometry::STGeomFromText('COMPOUNDCURVE ((2173251.19755045 260565.663264811 NULL 2000,2173324.62503405 260532.888690099 NULL 2080.4098),
 CIRCULARSTRING (2173324.62503405 260532.888690099 NULL 2080.4098,2173345.78352624 260520.72691965 NULL 0,2173364.04390489 260504.535902888 NULL 2129.3036),
 CIRCULARSTRING (2173364.04390489 260504.535902888 NULL 2129.3036,2173381.19882422 260470.679448103 NULL 0,2173378.16228123 260432.846523359 NULL 2206.1746),
 (2173378.16228123 260432.846523359 NULL 2206.1746,2173355.55940427 260371.804622516 NULL 2271.2667,2173350.99754606 260362.115766078 NULL 2281.9758),
 CIRCULARSTRING (2173350.99754606 260362.115766078 NULL 2281.9758,2173336.7026266 260144.609642233 NULL 0,2173474.30695651 259975.558445781 NULL 2728.2803),
 (2173474.30695651 259975.558445781 NULL 2728.2803,2173476.92754695 259974.081665367 NULL 2731.2883),
 CIRCULARSTRING (2173476.92754695 259974.081665367 NULL 2731.2883,2173644.89258743 259822.983578196 NULL 0,2173732.74541767 259614.837554961 NULL 3186.7865),
 CIRCULARSTRING (2173732.74541767 259614.837554961 NULL 3186.7865,2173749.05001496 259459.972709981 NULL 0,2173742.0037621 259304.411434516 NULL 3498.52))',2274) as geom
)
--SELECT [$(lrsowner)].[STFindPointByMeasure](a.geom, 2160, 500, 2, 4, 4) FROM Ramp_H as a

SELECT 0 as measure, A.geom from Ramp_H as a
union all
SELECT along.IntValue as measure, 
       [$(owner)].[STMakeLine] (
	     [$(lrsowner)].[STFindPointByMeasure](a.geom, along.IntValue, -1200, 2, 4, 4),
         [$(lrsowner)].[STFindPointByMeasure](a.geom, along.IntValue,  1200, 2, 4, 4), 
		 4, 4
       ) as StationLine
  FROM Ramp_H as a
      cross apply
      dbo.Generate_Series(
        a.geom.STStartPoint().M,
        a.geom.STEndPoint().M,
        20) as along
GO

with ramp_h as (
select geometry::STGeomFromText('COMPOUNDCURVE ((2173251.19755045 260565.663264811 NULL 2000,2173324.62503405 260532.888690099 NULL 2080.4098),
 CIRCULARSTRING (2173324.62503405 260532.888690099 NULL 2080.4098,2173345.78352624 260520.72691965 NULL 0,2173364.04390489 260504.535902888 NULL 2129.3036),
 CIRCULARSTRING (2173364.04390489 260504.535902888 NULL 2129.3036,2173381.19882422 260470.679448103 NULL 0,2173378.16228123 260432.846523359 NULL 2206.1746),
 (2173378.16228123 260432.846523359 NULL 2206.1746,2173355.55940427 260371.804622516 NULL 2271.2667,2173350.99754606 260362.115766078 NULL 2281.9758),
 CIRCULARSTRING (2173350.99754606 260362.115766078 NULL 2281.9758,2173336.7026266 260144.609642233 NULL 0,2173474.30695651 259975.558445781 NULL 2728.2803),
 (2173474.30695651 259975.558445781 NULL 2728.2803,2173476.92754695 259974.081665367 NULL 2731.2883),
 CIRCULARSTRING (2173476.92754695 259974.081665367 NULL 2731.2883,2173644.89258743 259822.983578196 NULL 0,2173732.74541767 259614.837554961 NULL 3186.7865),
 CIRCULARSTRING (2173732.74541767 259614.837554961 NULL 3186.7865,2173749.05001496 259459.972709981 NULL 0,2173742.0037621 259304.411434516 NULL 3498.52))', 2274) as geom
), Ramp_H_Segmentized as (
SELECT [$(lrsowner)].[STFindSegmentByMeasureRange] (a.geom,2100,2200,0.0,2,8,4) as segment
 FROM ramp_h as a      
)
select -1 as measure,a.geom from ramp_h as a
union all
SELECT along.IntValue as measure, 
       [$(owner)].[STMakeLine] (
           [$(lrsowner)].[STFindPointByMeasure](a.segment, along.IntValue, -500, 2, 4, 4),
           [$(lrsowner)].[STFindPointByMeasure](a.segment, along.IntValue, 500, 2, 4, 4), 4, 4) as StationLine
FROM Ramp_H_Segmentized as a
     cross apply
     dbo.Generate_Series(a.segment.STStartPoint().M, a.segment.STEndPoint().M, 20) as along;


with ramp_h as (
select geometry::STGeomFromText('COMPOUNDCURVE ((2173251.19755045 260565.663264811 NULL 2000,2173324.62503405 260532.888690099 NULL 2080.4098),
 CIRCULARSTRING (2173324.62503405 260532.888690099 NULL 2080.4098,2173345.78352624 260520.72691965 NULL 0,2173364.04390489 260504.535902888 NULL 2129.3036),
 CIRCULARSTRING (2173364.04390489 260504.535902888 NULL 2129.3036,2173381.19882422 260470.679448103 NULL 0,2173378.16228123 260432.846523359 NULL 2206.1746),
 (2173378.16228123 260432.846523359 NULL 2206.1746,2173355.55940427 260371.804622516 NULL 2271.2667,2173350.99754606 260362.115766078 NULL 2281.9758),
 CIRCULARSTRING (2173350.99754606 260362.115766078 NULL 2281.9758,2173336.7026266 260144.609642233 NULL 0,2173474.30695651 259975.558445781 NULL 2728.2803),
 (2173474.30695651 259975.558445781 NULL 2728.2803,2173476.92754695 259974.081665367 NULL 2731.2883),
 CIRCULARSTRING (2173476.92754695 259974.081665367 NULL 2731.2883,2173644.89258743 259822.983578196 NULL 0,2173732.74541767 259614.837554961 NULL 3186.7865),
 CIRCULARSTRING (2173732.74541767 259614.837554961 NULL 3186.7865,2173749.05001496 259459.972709981 NULL 0,2173742.0037621 259304.411434516 NULL 3498.52))', 2274) as geom
), Ramp_H_Segmentized as (
SELECT [$(lrsowner)].[STSplitSegmentByMeasure] (s.segment,2100,2200,0.0,2,8,4) as segment
  FROM ramp_h as a 
      cross apply
	  dbo.STSegmentize(a.geom,'MEASURE_RANGE',NULL,NULL,2100,2200,3,3,3) as s      
)
select -1 as measure,a.geom from ramp_h as a
union all
SELECT along.IntValue as measure, 
       [$(owner)].[STMakeLine] (
           [$(lrsowner)].[STFindPointByMeasure](a.segment, along.IntValue, -500, 2, 4, 4),
           [$(lrsowner)].[STFindPointByMeasure](a.segment, along.IntValue, 500, 2, 4, 4), 
		   4, 4
	  ).STBuffer(10.0) as StationLine
FROM Ramp_H_Segmentized as a
     cross apply
     dbo.Generate_Series(a.segment.STStartPoint().M, a.segment.STEndPoint().M, 20) as along;


