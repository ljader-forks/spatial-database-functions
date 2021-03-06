CREATE OR REPLACE package test_sc4o
as

  --%suite(SC4O Package Test Suite)

  --%test(Test ST_GeomFromEWKT)
  procedure test_st_geomfromewkt;
  --%test(Test ST_LRS_Dim and ST_LRS_IsMeasured)
  procedure test_st_delaunay_mgeom;

end;
/
show errors

CREATE OR REPLACE package body test_sc4o 
as

  g_multipoint_ewkt varchar2(32000) := 'SRID=32615;MULTIPOINT ((755441.542258283 3678850.38541675 9.14999999944121), (755438.136705691 3679051.52458636 9.86999999918044), (755642.681431119 3678853.79096725 10.0000000018626), (755639.275877972 3679054.93014137 10), (755635.870328471 3679256.06930606 8.62999999988824), (755843.82060051 3678857.19651868 10), (755840.415056435 3679058.33568674 9.99999999906868), (755837.009506021 3679259.47485623 10), (755959.586342714 3679438.15319976 5.94999999925494), (756044.959776444 3678860.6020602 9.95000000018626), (756041.554231838 3679061.74123334 10.0000000009313), (756038.148680523 3679262.88040789 9.26999999862164))';

  g_multipoint_geom mdsys.sdo_geometry := MDSYS.SDO_GEOMETRY(3005,32615,NULL,MDSYS.SDO_ELEM_INFO_ARRAY(1,1,12),MDSYS.SDO_ORDINATE_ARRAY(755441.542258283,3678850.38541675,9.14999999944121,755438.136705691,3679051.52458636,9.86999999918044,755642.681431119,3678853.79096725,10.0000000018626,755639.275877972,3679054.93014137,10,755635.870328471,3679256.06930606,8.62999999988824,755843.82060051,3678857.19651868,10,755840.415056435,3679058.33568674,9.99999999906868,755837.009506021,3679259.47485623,10,755959.586342714,3679438.15319976,5.94999999925494,756044.959776444,3678860.6020602,9.95000000018626,756041.554231838,3679061.74123334,10.0000000009313,756038.148680523,3679262.88040789,9.26999999862164));

  procedure test_st_geomfromewkt
  As
    v_geom   mdsys.sdo_geometry;
    v_relate varchar2(20);
  Begin
    v_geom := SC4O.ST_GeomFromEWKT(g_multipoint_ewkt);
    v_relate := sdo_geom.RELATE(v_geom,'DETERMINE',g_multipoint_geom,0.005);
    ut.expect( v_relate, 'Failed to compare ST_GeomFromEWKT to generated output' ).to_equal('EQUAL');
  END test_st_geomfromewkt;
  
  procedure test_st_delaunay_mgeom
  As
    v_geom mdsys.sdo_geometry;
  Begin
    v_geom := SC4O.ST_DelaunayTriangles(g_multipoint_geom,0.05,10);
    ut.expect( sdo_util.GETNUMELEM(), 'Failed to compare g_t_geometry.ST_LRS_Dim() to g_t_geometry.geom.get_lrs_dim()' ).to_equal(25);
  End test_st_delaunay_mgeom;

end;
/
show errors

set serveroutput on size unlimited
set long 800
set linesize 800
begin ut.run('test_sc4o'); end;

