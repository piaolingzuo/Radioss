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
Chd|  PMAIN3                        source/elements/beam/pmain3.F 
Chd|-- called by -----------
Chd|        PFORC3                        source/elements/beam/pforc3.F 
Chd|-- calls ---------------
Chd|        M2LAWPI                       source/materials/mat/mat002/m2lawpi.F
Chd|        MULAWP                        source/elements/beam/mulawp.F 
Chd|        ELBUFDEF_MOD                  ../common_source/modules/elbufdef_mod.F
Chd|====================================================================
      SUBROUTINE PMAIN3(ELBUF_STR,
     1                  JFT     ,JLT     ,NEL     ,NPT     ,MTN,
     2                  MAT     ,PID     ,NGL     ,PM      ,IPM,
     3                  GEO     ,IGEO    ,OFF     ,FOR     ,MOM,
     4                  EINT    ,AL      ,EPSP    ,BUFMAT  ,NPF,
     5                  TF      ,EXX     ,EXY     ,EXZ     ,KXX,
     6                  KYY     ,KZZ     ,F1      ,F2      ,F3 ,
     7                  M1      ,M2      ,M3      ,JTHE    ,TEMPEL)
C-----------------------------------------------
C   M o d u l e s
C-----------------------------------------------
      USE ELBUFDEF_MOD
C-----------------------------------------------
C   I m p l i c i t   T y p e s
C-----------------------------------------------
#include      "implicit_f.inc"
#include      "comlock.inc"
C-----------------------------------------------
C   G l o b a l   P a r a m e t e r s
C-----------------------------------------------
#include      "mvsiz_p.inc"
C-----------------------------------------------
C   C o m m o n   B l o c k s
C-----------------------------------------------
#include      "units_c.inc"
#include      "param_c.inc"
#include      "com01_c.inc"
#include      "com08_c.inc"
#include      "scr17_c.inc"
#include      "impl1_c.inc"
C-----------------------------------------------
C   D u m m y   A r g u m e n t s
C-----------------------------------------------
      INTEGER JFT,JLT,NEL,MTN,NPT,JTHE    
      INTEGER IPM(NPROPMI,*),IGEO(NPROPGI,*),PID(*),MAT(*),NPF(*),NGL(*)
      my_real 
     .   PM(NPROPM,*),GEO(NPROPG,*),EPSP(MVSIZ),BUFMAT(*),
     .   OFF(*),EINT(NEL,2),TF(*),AL(MVSIZ), 
     .   FOR(NEL,3),MOM(NEL,3),EXX(MVSIZ),EXY(MVSIZ),
     .   EXZ(MVSIZ),KXX(MVSIZ),KYY(MVSIZ),KZZ(MVSIZ),
     .   F1(MVSIZ),F2(MVSIZ),F3(MVSIZ),M1(MVSIZ),M2(MVSIZ),M3(MVSIZ),
     .   TEMPEL(MVSIZ),VOL(MVSIZ),RHOE(MVSIZ),RHOG(MVSIZ)
C
      TYPE (ELBUF_STRUCT_), TARGET :: ELBUF_STR
C-----------------------------------------------
C   L o c a l   V a r i a b l e s
C-----------------------------------------------
      INTEGER I1(MVSIZ),IFUNC(100)
      INTEGER I,J1,IPT,JPLA,NPAR,IADBUF,NFUNC,ISRATE,IPY,IPZ,IPA
      my_real 
     .   DEGMB(MVSIZ),DEGSH(MVSIZ),DEGFX(MVSIZ),YPT(MVSIZ),ZPT(MVSIZ),
     .   APT(MVSIZ),IXX(MVSIZ),IYY(MVSIZ),IZZ(MVSIZ),ETSE(MVSIZ),
     .   G(MVSIZ),E(MVSIZ),EPSPL(MVSIZ)
      my_real 
     .   DTINV,ASRATE,EPSPI,DMPM,DMPF,SPE,SPG,RHO,FACT,AREA,DMM,DMPFL
C=======================================================================
C       STRAIN RATE
C-------------------
      DO I=JFT,JLT                                              
        EPSPI  = HALF*(EXX(I)**2) + (HALF*EXY(I))**2 + (HALF*EXZ(I))**2
        EPSPI  = AL(I)*SQRT(THREE*EPSPI)/THREE_HALF                         
        ISRATE = IPM(3,MAT(I))                             
        IF (ISRATE > 0) THEN                                    
          ASRATE = MIN(ONE, PM(9,MAT(I))*DT1)
          EPSP(I)= ASRATE*EPSPI + (ONE - ASRATE)*EPSP(I)
        ELSE       
          EPSP(I)= EPSPI
        ENDIF                                                   
        EPSPL(I) = EPSP(I)                                     
      ENDDO                      
C-------------------
      DO I=JFT,JLT
        EXX(I) = EXX(I)*DT1
        EXY(I) = EXY(I)*DT1
        EXZ(I) = EXZ(I)*DT1
        KXX(I) = KXX(I)*DT1
        KYY(I) = KYY(I)*DT1
        KZZ(I) = KZZ(I)*DT1
      ENDDO
C
      DO I=JFT,JLT
        DEGMB(I) = FOR(I,1)*EXX(I)
        DEGSH(I) = FOR(I,2)*EXY(I)+FOR(I,3)*EXZ(I)
        DEGFX(I) = MOM(I,1)*KXX(I)+MOM(I,2)*KYY(I)+MOM(I,3)*KZZ(I)
      ENDDO
C
      IF (ISIGI == 0 .OR. (ISIGI /= 0 .AND. TT /= ZERO)) THEN
        DO I=JFT,JLT
          FOR(I,1) = ZERO
          FOR(I,2) = ZERO
          FOR(I,3) = ZERO
          MOM(I,1) = ZERO
          MOM(I,2) = ZERO
          MOM(I,3) = ZERO
        ENDDO
      ENDIF
C-----------------      
      IF (MTN == 2) THEN
        CALL M2LAWPI(ELBUF_STR,
     1               JFT    ,JLT    ,NPT    ,PM     ,GEO, 
     2               FOR    ,MOM    ,EINT   ,OFF    ,MAT,   
     3               PID    ,EPSPL  ,EXX    ,EXY    ,EXZ,  
     4               KXX    ,KYY    ,KZZ    ,AL     ,NEL)
      ELSEIF (MTN > 28) THEN   
C---    User laws
        CALL MULAWP(ELBUF_STR,
     1              JFT     ,JLT     ,NEL     ,NPT     ,MTN,
     2              MAT     ,PID     ,NGL     ,PM      ,IPM,	 
     3              GEO     ,IGEO    ,OFF     ,FOR     ,MOM,	 
     4              EINT    ,AL      ,EPSPL   ,BUFMAT  ,NPF,
     5              TF      ,EXX     ,EXY     ,EXZ     ,KXX,
     6              KYY     ,KZZ     ,JTHE    ,TEMPEL)
       ENDIF      
C-------------------------------------
      DO I=JFT,JLT
        FOR(I,1)=FOR(I,1)*OFF(I)
        FOR(I,2)=FOR(I,2)*OFF(I)
        FOR(I,3)=FOR(I,3)*OFF(I)
        MOM(I,1)=MOM(I,1)*OFF(I)
        MOM(I,2)=MOM(I,2)*OFF(I)
        MOM(I,3)=MOM(I,3)*OFF(I)
      ENDDO
C---------------------------
C     AMORTISSEMENT
C---------------------------
      DTINV = DT1/MAX(DT1**2,EM20)  
      IF (IMPL_S > 0 .AND. IDYNA == 0) DTINV = ZERO
C
      DO I=JFT,JLT                                             
        E(I)  = PM(20,MAT(I))                    
        G(I)  = PM(22,MAT(I))                    
        RHO   = PM(1 ,MAT(I))
        IXX(I)= GEO(4,PID(I))
        IYY(I)= GEO(2,PID(I))
        IZZ(I)= GEO(18,PID(I))
        AREA  = GEO(1 ,PID(I))
        DMPM  = GEO(16,PID(I))                                    
        DMPF  = GEO(17,PID(I)) 
        VOL(I) = AREA*AL(I)
C
        SPE   = DTINV *  SQRT(TWO*RHO*E(I))             
        SPG   = DTINV *  SQRT(TWO*RHO*G(I))
        DMM  =  SPE* VOL(I)
        DMPFL = DMPF*AL(I)
        F1(I) = FOR(I,1) + DMPM*EXX(I)*DMM   
        F2(I) = FOR(I,2) + DMPF*EXY(I)*DMM    
        F3(I) = FOR(I,3) + DMPF*EXZ(I)*DMM   
        M1(I) = MOM(I,1) + DMPFL*KXX(I)*SPG*IXX(I)
        M2(I) = MOM(I,2) + DMPFL*KYY(I)*SPE*IYY(I)
        M3(I) = MOM(I,3) + DMPFL*KZZ(I)*SPE*IZZ(I)
      ENDDO                 
C-------------------------------------
      DO I=JFT,JLT
        DEGMB(I) = DEGMB(I) + FOR(I,1)*EXX(I)
        DEGSH(I) = DEGSH(I) + FOR(I,2)*EXY(I) + FOR(I,3)*EXZ(I)
        DEGFX(I) = DEGFX(I) 
     .           + MOM(I,1)*KXX(I) + MOM(I,2)*KYY(I) + MOM(I,3)*KZZ(I)
        FACT = HALF*OFF(I)*AL(I)
        EINT(I,1)  = EINT(I,1) + FACT*(DEGMB(I)+DEGSH(I))
        EINT(I,2)  = EINT(I,2) + FACT* DEGFX(I)
      ENDDO
C----------------------------
C     TEST DE RUPTURE
C---------converged implicit-------------------
      DO I=JFT,JLT
        IF (OFF(I) == FOUR_OVER_5 .AND. IMCONV == 1) THEN 
          IDEL7NOK = 1            
#include "lockon.inc"
          WRITE(IOUT, 1000) NGL(I)
          WRITE(ISTDO,1100) NGL(I),TT
#include "lockoff.inc"
        ENDIF
      ENDDO
C      
      DO I=JFT,JLT
        IF (OFF(I) < EM01)  OFF(I) = ZERO
        IF (OFF(I) < ONE  )  OFF(I) = OFF(I)*FOUR_OVER_5
      ENDDO      
C------------------------------------------
 1000 FORMAT(1X,'-- RUPTURE OF BEAM ELEMENT NUMBER ',I10)
 1100 FORMAT(1X,'-- RUPTURE OF BEAM ELEMENT :',I10,' AT TIME :',G11.4)
C------------------------------------------
      RETURN
      END SUBROUTINE PMAIN3
