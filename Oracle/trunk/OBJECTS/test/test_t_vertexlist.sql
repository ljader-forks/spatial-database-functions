CREATE OR REPLACE PACKAGE test_t_vertexlist 
AUTHID DEFINER
IS

   /* generated by utPLSQL for SQL Developer on 2019-07-25 15:27:31 */

   --%suite(test_t_vertexlist)
   --%suitepath(alltests)
   
   --%test
   PROCEDURE t_vertexlist;

   --%test
   PROCEDURE isdeleted;

   --%test
   PROCEDURE setdeleted;

   --%test
   PROCEDURE getcoordinates;

   --%test
   PROCEDURE isredundant;

   --%test
   PROCEDURE addVertex;

   --%test
   PROCEDURE addVertices;

   --%test
   PROCEDURE addsegment;

   --%test
   PROCEDURE addfirstsegment;

   --%test
   PROCEDURE addlastsegment;

   --%test
   PROCEDURE closering;

   --%test
   PROCEDURE setminimumvertexdistance;

END test_t_vertexlist;
/

CREATE OR REPLACE PACKAGE BODY test_t_vertexlist IS

   /* generated by utPLSQL for SQL Developer on 2019-07-25 15:27:31 */

   --
   -- test t_vertexlist case 1: ...
   --
   PROCEDURE t_vertexlist 
   IS
      l_actual     INTEGER := 0;
      l_expected   INTEGER := 4;
      v_vertexlist spdba.T_VertexList;
      v_vertices   spdba.T_Vertices;
   BEGIN
      -- populate actual
      -- t_vertexlist.t_vertexlist;
      v_vertexlist  := new spdba.T_VertexList(p_vertex => new spdba.T_Vertex(p_x => 0, p_y => 0));
      v_vertexList.addVertex(new spdba.T_Vertex(p_x => 1, p_y => 1));
      v_vertices    := new spdba.T_Vertices();
      v_vertices.EXTEND(2);
      v_vertices(1) := spdba.T_Vertex(p_x => 2, p_y => 2);
      v_vertices(2) := spdba.T_Vertex(p_x => 3, p_y => 3);
      v_vertexlist.addVertices(p_vertices=>v_vertices,isForward=>true);
      -- populate expected
      l_actual := v_vertexList.getNumCoordinates();
      -- assert
      ut.expect(l_actual).to_equal(l_expected);
   END t_vertexlist;

   --
   -- test isdeleted case 1: ...
   --
   PROCEDURE isdeleted IS
      l_actual     INTEGER := 0;
      l_expected   INTEGER := 1;
      v_vertexlist spdba.T_VertexList;
      v_vertices   spdba.T_Vertices;
      v_vertex     spdba.T_Vertex;
   BEGIN
      -- populate actual
      -- t_vertexlist.t_vertexlist;
      v_vertexlist  := new spdba.T_VertexList(p_vertex => new spdba.T_Vertex(p_x => 0, p_y => 0));
      v_vertexList.addVertex(new spdba.T_Vertex(p_x => 1, p_y => 1));
      v_vertices    := new spdba.T_Vertices();
      v_vertices.EXTEND(2);
      v_vertex      := new spdba.T_Vertex(p_x => 2, p_y => 2);
      v_vertex.ST_setDeleted(p_deleted=>1);
      v_vertices(1) := new spdba.T_Vertex(v_vertex);
      v_vertices(2) := spdba.T_Vertex(p_x => 3, p_y => 3);
      v_vertexlist.addVertices(p_vertices=>v_vertices,isForwrad=>true);
      -- populate expected
      l_actual := v_vertexList.isDeleted(3);
      -- assert
      ut.expect(l_actual).to_equal(l_expected);
   END isdeleted;

   --
   -- test setdeleted case 1: ...
   --
   PROCEDURE setdeleted IS
      l_actual     INTEGER := 0;
      l_expected   INTEGER := 1;
      v_vertexlist spdba.T_VertexList;
      v_vertices   spdba.T_Vertices;
      v_vertex     spdba.T_Vertex;
   BEGIN
      -- populate actual
      -- t_vertexlist.setdeleted;
      v_vertexlist  := new spdba.T_VertexList(p_vertex => new spdba.T_Vertex(p_x => 0, p_y => 0));
      v_vertexList.addVertex(new spdba.T_Vertex(p_x => 1, p_y => 1));
      v_vertexList.setDeleted(p_index=>1,p_deleted=>1);
      -- populate expected
      l_actual := v_vertexList.isDeleted(1);
      -- assert
      ut.expect(l_actual).to_equal(l_expected);
   END setdeleted;

   --
   -- test getcoordinates case 1: ...
   --
   PROCEDURE getcoordinates IS
      l_actual     INTEGER := 4;
      l_expected   INTEGER := 5;
      v_vertexlist spdba.T_VertexList;
      v_vertices   spdba.T_Vertices;
   BEGIN
      -- populate actual
      -- t_vertexlist.getcoordinates;
      v_vertexlist  := new spdba.T_VertexList(p_vertex => new spdba.T_Vertex(p_x => 0, p_y => 0));
      v_vertexList.addVertex(new spdba.T_Vertex(p_x => 1, p_y => 1));
      v_vertexList.addVertex(new spdba.T_Vertex(p_x => 2, p_y => 2));
      v_vertexList.addVertex(new spdba.T_Vertex(p_x => 3, p_y => 3));
      v_vertexList.addVertex(new spdba.T_Vertex(p_x => 4, p_y => 4));
      -- populate expected
      v_vertices := v_vertexList.getCoordinates();
      l_actual   := v_vertexList.getNumCoordinates();
      -- assert
      ut.expect(l_actual).to_equal(l_expected);
   END getcoordinates;

   --
   -- test isredundant case 1: ...
   --
   PROCEDURE isredundant IS
      l_actual     INTEGER := 1;
      l_expected   INTEGER := 1;
      v_vertexlist spdba.T_VertexList;
      v_vertices   spdba.T_Vertices;
   BEGIN
      -- populate actual
      -- t_vertexlist.isredundant;
      v_vertexlist  := new spdba.T_VertexList(p_vertex => new spdba.T_Vertex(p_x => 0, p_y => 0));
      v_vertexList.addVertex(new spdba.T_Vertex(p_x => 1, p_y => 1));
      v_vertexList.addVertex(new spdba.T_Vertex(p_x => 2, p_y => 2));
      v_vertexList.addVertex(new spdba.T_Vertex(p_x => 3, p_y => 3));
      -- populate expected
      l_actual := case when v_vertexList.isRedundant(new spdba.T_Vertex(p_x => 3, p_y => 3)) then 1 else 0 end;  --> Reduntant
      -- assert
      ut.expect(l_actual).to_equal(l_expected);
   END isredundant;

   --
   -- test addVertex case 1: ...
   --
   PROCEDURE addVertex IS
      l_actual   INTEGER := 2;
      l_expected INTEGER := 2;
      v_vertexlist spdba.T_VertexList;
      v_vertices   spdba.T_Vertices;
   BEGIN
      -- populate actual
      -- t_vertexlist.addVertex;
      v_vertexlist  := new spdba.T_VertexList(p_vertex => new spdba.T_Vertex(p_x => 0, p_y => 0));
      v_vertexList.addVertex(new spdba.T_Vertex(p_x => 1, p_y => 1));
      -- populate expected
      -- ...
      l_actual := v_vertexList.getNumCoordinates();
      -- assert
      ut.expect(l_actual).to_equal(l_expected);
   END addVertex;

   --
   -- test addVertices case 1: ...
   --
   PROCEDURE addVertices 
   IS
      l_actual   INTEGER := 4;
      l_expected INTEGER := 4;
      v_vertexlist spdba.T_VertexList;
      v_vertices   spdba.T_Vertices;
   BEGIN
      -- populate actual
      -- t_vertexlist.addVertices;
      v_vertices    := new spdba.T_Vertices(
                                 spdba.T_Vertex(p_x => 0, p_y => 0),
                                 spdba.T_Vertex(p_x => 1, p_y => 1),
                                 spdba.T_Vertex(p_x => 2, p_y => 2),
                                 spdba.T_Vertex(p_x => 3, p_y => 3)
                     );

      v_vertexlist  := new spdba.T_VertexList();
      v_vertexlist.addVertices(p_Vertices=>v_vertices,isForward=>true);
      -- populate expected
      -- ...
      l_actual := v_vertexList.getNumCoordinates();

      -- assert
      ut.expect(l_actual).to_equal(l_expected);
   END addVertices;

   --
   -- test addsegments case 1: ...
   --
   PROCEDURE addSegment IS
      l_actual     INTEGER := 0;
      l_expected   INTEGER := 2;
      v_vertexlist spdba.T_VertexList;
      v_segment    spdba.T_Segment;
   BEGIN
      -- populate actual
      -- t_vertexlist.addsegments;
      v_segment := new spdba.T_Segment(
                                 p_line       => mdsys.sdo_geometry(2002,null,null,sdo_elem_info_array(1,2,1),sdo_ordinate_array(0,0,1,1)),
                                 p_segment_id => 1
                     );
      v_vertexlist  := new spdba.T_VertexList(v_segment);
      -- populate expected
      -- ...
      l_actual := v_vertexList.getNumCoordinates();
      -- assert
      ut.expect(l_actual).to_equal(l_expected);
   END addsegment;

   --
   -- test addfirstsegment case 1: ...
   --
   PROCEDURE addFirstSegment 
   IS
      l_actual     INTEGER := 0;
      l_expected   INTEGER := 2;
      v_vertexlist spdba.T_VertexList;
      v_segment    spdba.T_Segment;
   BEGIN
      -- populate actual
      -- t_vertexlist.addfirstsegment;
      v_vertexlist  := new spdba.T_VertexList(spdba.T_Vertex(p_x => 0, p_y => 0));
      v_vertexlist.AddFirstSegment(p_offset => spdba.T_Vertex(p_x => 1, p_y => 1));
      -- populate expected
      -- ...
      l_actual := v_vertexList.getNumCoordinates();
      -- assert
      ut.expect(l_actual).to_equal(l_expected);
   END addfirstsegment;

   --
   -- test addlastsegment case 1: ...
   --
   PROCEDURE addLastSegment IS
      l_actual   INTEGER := 0;
      l_expected INTEGER := 2;
      v_vertexlist spdba.T_VertexList;
      v_segment    spdba.T_Segment;
   BEGIN
      -- populate actual
      -- t_vertexlist.addLastSegment;
      v_vertexlist  := new spdba.T_VertexList( spdba.T_Vertex(p_x => 0, p_y => 0));
      v_vertexlist.AddLastSegment(p_offset => spdba.T_Vertex(p_x => 1, p_y => 1));
      -- populate expected
      -- ...
      l_actual := v_vertexList.getNumCoordinates();
      -- assert
      ut.expect(l_actual).to_equal(l_expected);
   END addlastsegment;

   --
   -- test closering case 1: ...
   --
   PROCEDURE closeRing IS
      l_actual     INTEGER := 0;
      l_expected   INTEGER := 5;
      v_vertexlist spdba.T_VertexList;
      v_segment    spdba.T_Segment;
   BEGIN
      -- populate actual
      -- t_vertexlist.closeRing;
      v_segment := new spdba.T_Segment(
                                 p_line       => mdsys.sdo_geometry(2002,null,null,sdo_elem_info_array(1,2,1),sdo_ordinate_array(0,0,1,0)),
                                 p_segment_id => 1
                     );
      v_vertexlist  := new spdba.T_VertexList(v_segment);
      v_vertexlist.addVertex(spdba.T_Vertex(p_x => 1, p_y => 1));
      v_vertexlist.addVertex(spdba.T_Vertex(p_x => 0, p_y => 1));
      v_vertexlist.closeRing();
      -- populate expected
      -- ...
      l_actual := v_vertexList.getNumCoordinates();
      -- assert
      ut.expect(l_actual).to_equal(l_expected);
   END closering;

   --
   -- test setminimumvertexdistance case 1: ...
   --
   PROCEDURE setminimumvertexdistance IS
      l_actual     Number := 0;
      l_expected   Number := 0.000001;
      v_vertexlist spdba.T_VertexList;
   BEGIN
      -- populate actual
      -- t_vertexlist.setminimumvertexdistance;
      v_vertexlist  := new spdba.T_VertexList( spdba.T_Vertex(p_x => 0, p_y => 0));
      v_vertexList.setMinimumVertexDistance(p_distance => 1.0);
      -- populate expected
      -- ...
      l_actual := v_vertexList.getMinimumVertexDistance();
      -- assert
      ut.expect(l_actual).to_equal(l_expected);
   END setminimumvertexdistance;

END test_t_vertexlist;
/

