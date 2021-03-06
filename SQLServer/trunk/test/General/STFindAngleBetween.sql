SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
GO

PRINT 'Testing [$(cogoowner)].[STFindAngleBetween] ...';
GO

With data as (
  select geometry::STGeomFromText('LINESTRING( 0  0, 10 10)',0) as line,
         geometry::STGeomFromText('LINESTRING(10 10, 20 0)',0) as next_line
)
select g.IntValue as side,
       [$(cogoowner)].[STFindAngleBetween] ( a.line, a.next_line, g.Intvalue )
  from data as a
       cross apply
       [$(owner)].[Generate_Series](-1,1,1) as g
 where g.IntValue <> 0;
GO

