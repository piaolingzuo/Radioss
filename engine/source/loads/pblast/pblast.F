Copyright>        OpenRadioss
Copyright>        Copyright (C) 1986-2023 Altair Engineering Inc.
Copyright>
Copyright>        This program is free software: you can redistribute it and/or modify
Copyright>        it under the terms of the GNU Affero General Public License as published by
Copyright>        the Free Software Foundation, either version 3 of the License, or
Copyright>        (at your option) any later version.
Copyright>
Copyright>        This program is distributed in the hope that it will be useful,
Copyright>        but WITHOUT ANY WARRANTY; without even the implied warranty of
Copyright>        MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
Copyright>        GNU Affero General Public License for more details.
Copyright>
Copyright>        You should have received a copy of the GNU Affero General Public License
Copyright>        along with this program.  If not, see <https://www.gnu.org/licenses/>.
Copyright>
Copyright>
Copyright>        Commercial Alternative: Altair Radioss Software
Copyright>
Copyright>        As an alternative to this open-source version, Altair also offers Altair Radioss
Copyright>        software under a commercial license.  Contact Altair to discuss further if the
Copyright>        commercial version may interest you: https://www.altair.com/radioss/.
Chd|====================================================================
Chd|  PBLAST                        source/loads/pblast/pblast.F  
Chd|-- called by -----------
Chd|        RESOL                         source/engine/resol.F         
Chd|-- calls ---------------
Chd|        MY_BARRIER                    source/system/machine.F       
Chd|        PBLAST_1                      source/loads/pblast/pblast_1.F
Chd|        PBLAST_2                      source/loads/pblast/pblast_2.F
Chd|        PBLAST_3                      source/loads/pblast/pblast_3.F
Chd|        GROUPDEF_MOD                  ../common_source/modules/groupdef_mod.F
Chd|        H3D_MOD                       share/modules/h3d_mod.F       
Chd|        PBLAST_MOD                    ../common_source/modules/pblast_mod.F
Chd|====================================================================
      SUBROUTINE PBLAST (ILOADP  ,FAC     ,A       , V       ,X       ,
     1                   IADC    ,FSKY    ,FSKYV   ,LLOADP   ,FEXT    ,
     2                   ITAB    ,H3D_DATA)
C-----------------------------------------------
C   M o d u l e s
C----------------------------------------------- 
      USE H3D_MOD 
      USE PBLAST_MOD
      USE GROUPDEF_MOD      
C-----------------------------------------------
C   I m p l i c i t   T y p e s
C-----------------------------------------------
#include      "implicit_f.inc"
#include      "comlock.inc"
#include      "param_c.inc"
C-----------------------------------------------
C   C o m m o n   B l o c k s
C-----------------------------------------------
#include      "com04_c.inc"
#include      "com06_c.inc"
#include      "com08_c.inc"
#include      "mvsiz_p.inc"
#include      "tabsiz_c.inc"
C-----------------------------------------------
C   D u m m y   A r g u m e n t s
C-----------------------------------------------
      INTEGER,INTENT(IN) :: LLOADP(SLLOADP)
      INTEGER,INTENT(IN) :: ILOADP(SIZLOADP,NLOADP)
      INTEGER,INTENT(IN) :: IADC(*)
      INTEGER, INTENT(IN) :: ITAB(NUMNOD)
      my_real,INTENT(IN) :: FAC(LFACLOAD,NLOADP),V(3,NUMNOD),X(3,NUMNOD)
      my_real,INTENT(INOUT) :: A(3,NUMNOD),FSKY(8,SFSKY/8), FSKYV(SFSKY/8,8),FEXT(3,NUMNOD)
      TYPE(H3D_DATABASE),INTENT(IN) :: H3D_DATA
C-----------------------------------------------
C   L o c a l   V a r i a b l e s
C-----------------------------------------------
       INTEGER :: NL, ABAC_ID, NDT, NDT0, ID, II, IJK, NN(4), NNOD, IAD , IL
       my_real :: T0INF_LOC, TFEXT_LOC, T_STOP, TDET
       LOGICAL :: IS_RESET
C-----------------------------------------------
C   D e s c r i p t i o n
C-----------------------------------------------
C this subroutines is applying pressure load to
C a segment submitted to a blast wave which
C characteristics are built from TM5-1300 abacuses which are in unit system {cm g mus, bar},  pressure must also be converted into Mbar before switching from unit system.
C-----------------------------------------------
C   P r e - C o n d i t i o n
C-----------------------------------------------
       DT_PBLAST = EP20
       T0INF_PBLAST = EP20       
       IDT_PBLAST = 0      

       IF(NLOADP_B==0)THEN
         RETURN 
       ENDIF     
       
C-----------------------------------------------,
C   S o u r c e   C o d e
C-----------------------------------------------
!$OMP PARALLEL
!$OMP+ SHARED(FAC,A,V,X,TFEXT,IADC,FSKY,FSKYV,LLOADP,FEXT,ITAB,H3D_DATA,TT,ILOADP)
!$OMP+ SHARED(T0INF_PBLAST,PBLAST_TAB,PBLAST_DATA)
!$OMP+ PRIVATE(ABAC_ID,ID,NDT,NDT0,T0INF_LOC,NL,TFEXT_LOC)
       
       !-----------------------------------------------
       !   LOOP OVER all /LOAD/PBLAST options
       !----------------------------------------------- 
       DO NL=NLOADP_F+1, NLOADP_F+NLOADP_B

         ABAC_ID  = ILOADP(07,NL)
         ID       = ILOADP(08,NL) !user_id
         NDT      = PBLAST_NDT
         NDT0     = ILOADP(10,NL)
         TDET     = FAC(01,NL)
         T_STOP   = FAC(13,NL)
         
         IL       = NL-NLOADP_F
         IS_RESET = PBLAST_TAB(IL)%IS_RESET

         IF(NDT0/=0) NDT = NDT0
                  
         TFEXT_LOC = ZERO
         T0INF_LOC = EP20

         IF(TT >= TDET .AND. TT <= T_STOP)THEN
           SELECT CASE(ABAC_ID)
             CASE(1)
               !--- LOADING MODEL : FREE AIR, SPHERICAL CHARGE
               CALL PBLAST_1(
     1                       ILOADP  ,FAC      ,A        ,V         ,X        ,
     2                       IADC    ,FSKY     ,FSKYV    ,LLOADP    ,FEXT     ,
     3                       ITAB    ,H3D_DATA ,NL       ,T0INF_LOC ,TFEXT_LOC)
     
             CASE(2)
               !--- LOADING MODEL : GROUND REFLECTION, HEMISPHERICAL CHARGE
               CALL PBLAST_2(
     1                       ILOADP  ,FAC      ,A        ,V         ,X        ,
     2                       IADC    ,FSKY     ,FSKYV    ,LLOADP    ,FEXT     ,
     3                       ITAB    ,H3D_DATA ,NL       ,T0INF_LOC ,TFEXT_LOC)        
             CASE(3)
               !--- LOADING MODEL : SURFACE BURST, SPHERICAL CHARGE
               CALL PBLAST_3(
     1                       ILOADP  ,FAC      ,A        ,V         ,X        ,
     2                       IADC    ,FSKY     ,FSKYV    ,LLOADP    ,FEXT     ,
     3                       ITAB    ,H3D_DATA ,NL       ,T0INF_LOC ,TFEXT_LOC)
     
             END SELECT 
             
         ELSEIF(TT > T_STOP)THEN         
         
           IF(.NOT. IS_RESET)THEN
            ! FLUSH fsky array to 0.
!$OMP DO SCHEDULE(GUIDED,MVSIZ)           
             DO II = 1,ILOADP(1,NL)/4
               !nodes of structural face : N1,N2,N3,N4
               NN(1)=LLOADP(ILOADP(4,NL)+4*(II-1))
               NN(2)=LLOADP(ILOADP(4,NL)+4*(II-1)+1)
               NN(3)=LLOADP(ILOADP(4,NL)+4*(II-1)+2)
               NN(4)=LLOADP(ILOADP(4,NL)+4*(II-1)+3)
               IF(NN(4) /= 0 .AND.
     .            NN(1) /= NN(2) .AND. NN(1) /= NN(3) .AND. NN(1) /= NN(4) .AND.
     .            NN(2) /= NN(3) .AND. NN(2) /= NN(4) .AND.
     .            NN(3) /= NN(4) )THEN
                 NNOD=4
               ELSE
                 NNOD=3
               ENDIF
               DO IJK=1,NNOD
                 IAD = IADC(ILOADP(4,NL)+4*(II-1)+(IJK-1))  ! node indexes in FSKY related to current option /LOAD/PBLAST
                 FSKY(1:3,IAD) = ZERO
               ENDDO
               PBLAST_TAB(IL)%IS_RESET = .TRUE.
             ENDDO! next II
!$OMP END DO          
           ENDIF!(.NOT. IS_RESET)
         
         ENDIF

#include "lockon.inc"
         TFEXT = TFEXT + TFEXT_LOC
         ! Time Step (DT_PBLAST) and corresponding option id (IDT_PBLAST)
         IF(T0INF_LOC/NDT<DT_PBLAST) THEN
           IDT_PBLAST  = ID 
           DT_PBLAST = T0INF_LOC/NDT
         ENDIF      
#include  "lockoff.inc"

           CALL MY_BARRIER()
                
       ENDDO !next NL

!$OMP END PARALLEL
                     

      END SUBROUTINE
