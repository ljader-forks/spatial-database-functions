SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
GO

PRINT 'Testing [$(owner)].[STIsGeo] ...';
GO

IF EXISTS ( SELECT * FROM sysobjects WHERE id = object_id (N'[$(owner)].[foo]') AND xtype = N'U')
BEGIN
  DROP TABLE [$(owner)].[foo];
  PRINT 'Dropped [$(owner)].[foo] ...';
END;
GO

CREATE TABLE [$(owner)].[foo] (foo_id integer, geog geography, geom geometry);
GO
select dbo.STIsGeo('$(owner)',NULL,'geog')  as isGeo;
GO
select dbo.STIsGeo('$(owner)','foo','geog') as isGeo;
GO
select dbo.STIsGeo('$(owner)','foo','geom') as isGeo;
GO

IF EXISTS ( SELECT * FROM sysobjects WHERE id = object_id (N'[$(owner)].[vw_foo]') AND xtype = N'V')
BEGIN
  DROP VIEW [$(owner)].[vw_foo;]
  PRINT 'Dropped [$(owner)].[vw_foo] ...';
END;
GO

create view [$(owner)].vw_foo as select foo_id, geog from [$(owner)].[foo] as f;
GO
select [$(owner)].STIsGeo('$(owner)','vw_foo','geom') as isGeo;
GO
select [$(owner)].STIsGeo('$(owner)','vw_foo','geog') as isGeo;
GO
drop view  [$(owner)].[vw_foo];
GO
drop table [$(owner)].[foo];
GO

