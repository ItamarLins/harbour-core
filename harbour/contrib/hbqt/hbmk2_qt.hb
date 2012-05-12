/*
 * $Id$
 */

/*
 * hbmk2 plugin script, implementing support for QT specific features
 *
 * Copyright 2010 Viktor Szakats (harbour syenar.net)
 * Copyright 2010 Pritpal Bedi <bedipritpal@hotmail.com> (qth->prg/cpp generator and hbqtui_gen_prg())
 * www - http://harbour-project.org
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 2 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 675 Mass Ave, Cambridge, MA 02139, USA (or visit
 * their web site at http://www.gnu.org/).
 *
 */

#pragma warninglevel=3
#pragma -km+
#pragma -ko+

#include "directry.ch"
#include "hbclass.ch"

#define I_( x )                 hb_i18n_gettext( x )

#if defined( __HBSCRIPT__HBMK )

FUNCTION hbmk2_plugin_qt( hbmk2 )
   LOCAL cRetVal := ""

   LOCAL cSrc
   LOCAL cDst
   LOCAL tSrc
   LOCAL tDst

   LOCAL cDstCPP, cDstDOC
   LOCAL tDstCPP

   LOCAL cTmp
   LOCAL cPRG

   LOCAL cCommand
   LOCAL nError
   LOCAL lBuildIt

   SWITCH hbmk2[ "cSTATE" ]
   CASE "init"

      hbmk2_Register_Input_File_Extension( hbmk2, ".qrc" )
      hbmk2_Register_Input_File_Extension( hbmk2, ".ui" )
      hbmk2_Register_Input_File_Extension( hbmk2, ".hpp" )
      hbmk2_Register_Input_File_Extension( hbmk2, ".h" )
      hbmk2_Register_Input_File_Extension( hbmk2, ".qth" )

      EXIT

   CASE "pre_all"

      /* Gather input parameters */

      hbmk2[ "vars" ][ "aQRC_Src" ] := {}
      hbmk2[ "vars" ][ "aUIC_Src" ] := {}
      hbmk2[ "vars" ][ "aMOC_Src" ] := {}
      hbmk2[ "vars" ][ "aQTH_Src" ] := {}

      hbmk2[ "vars" ][ "qtmodule" ] := ""
      hbmk2[ "vars" ][ "qtver" ] := ""
      hbmk2[ "vars" ][ "qthdocdir" ] := ""

      FOR EACH cSrc IN hbmk2[ "params" ]
         IF Left( cSrc, 1 ) == "-"
            DO CASE
            CASE Left( cSrc, Len( "-qtver=" ) ) == "-qtver="
               hbmk2[ "vars" ][ "qtver" ] := SubStr( cSrc, Len( "-qtver=" ) + 1 )
            CASE Left( cSrc, Len( "-qtmodule=" ) ) == "-qtmodule="
               hbmk2[ "vars" ][ "qtmodule" ] := SubStr( cSrc, Len( "-qtmodule=" ) + 1 )
            CASE Left( cSrc, Len( "-qthdocdir=" ) ) == "-qthdocdir="
               hbmk2[ "vars" ][ "qthdocdir" ] := SubStr( cSrc, Len( "-qthdocdir=" ) + 1 )
            ENDCASE
         ELSE
            SWITCH Lower( hb_FNameExt( cSrc ) )
            CASE ".qrc"
               AAdd( hbmk2[ "vars" ][ "aQRC_Src" ], cSrc )
               EXIT
            CASE ".ui"
               AAdd( hbmk2[ "vars" ][ "aUIC_Src" ], cSrc )
               EXIT
            CASE ".hpp"
            CASE ".h"
               AAdd( hbmk2[ "vars" ][ "aMOC_Src" ], cSrc )
               EXIT
            CASE ".qth"
               AAdd( hbmk2[ "vars" ][ "aQTH_Src" ], cSrc )
               EXIT
            ENDSWITCH
         ENDIF
      NEXT

      /* Create output file lists */

      hbmk2[ "vars" ][ "aQRC_Dst" ] := {}
      hbmk2[ "vars" ][ "aQRC_PRG" ] := {}
      FOR EACH cSrc IN hbmk2[ "vars" ][ "aQRC_Src" ]
         cDst := hbmk2_FNameDirExtSet( "rcc_" + hb_FNameName( cSrc ), hbmk2[ "cWorkDir" ], ".qrb" )
         AAdd( hbmk2[ "vars" ][ "aQRC_Dst" ], cDst )
         cDst := hbmk2_FNameDirExtSet( "rcc_" + hb_FNameName( cSrc ), hbmk2[ "cWorkDir" ], ".prg" )
         AAdd( hbmk2[ "vars" ][ "aQRC_PRG" ], cDst )
         hbmk2_AddInput_PRG( hbmk2, cDst )
      NEXT

      hbmk2[ "vars" ][ "aUIC_Dst" ] := {}
      FOR EACH cSrc IN hbmk2[ "vars" ][ "aUIC_Src" ]
         cDst := hbmk2_FNameDirExtSet( "uic_" + hb_FNameName( cSrc ), hbmk2[ "cWorkDir" ], ".prg" )
         AAdd( hbmk2[ "vars" ][ "aUIC_Dst" ], cDst )
         hbmk2_AddInput_PRG( hbmk2, cDst )
      NEXT

      hbmk2[ "vars" ][ "aMOC_Dst" ] := {}
      FOR EACH cSrc IN hbmk2[ "vars" ][ "aMOC_Src" ]
         cDst := hbmk2_FNameDirExtSet( "moc_" + hb_FNameName( cSrc ), hbmk2[ "cWorkDir" ], ".cpp" )
         AAdd( hbmk2[ "vars" ][ "aMOC_Dst" ], cDst )
         hbmk2_AddInput_CPP( hbmk2, cDst )
      NEXT

      hbmk2[ "vars" ][ "aQTH_CPP" ] := {}
      hbmk2[ "vars" ][ "aQTH_DOC" ] := {}
      FOR EACH cSrc IN hbmk2[ "vars" ][ "aQTH_Src" ]
         cDst := hbmk2_FNameDirExtSet( hb_FNameName( cSrc ), hbmk2[ "cWorkDir" ], ".cpp" )
         AAdd( hbmk2[ "vars" ][ "aQTH_CPP" ], cDst )
         hbmk2_AddInput_CPP( hbmk2, cDst )
         cDst := hb_PathNormalize( hbmk2_FNameDirExtSet( "class_" + Lower( hb_FNameName( cSrc ) ), hb_FNameDir( cSrc ) + hbmk2[ "vars" ][ "qthdocdir" ] + "en" + hb_ps(), ".txt" ) )
         AAdd( hbmk2[ "vars" ][ "aQTH_DOC" ], cDst )

         IF qth_is_extended( cSrc )
            AAdd( hbmk2[ "vars" ][ "aMOC_Src" ], hbmk2_FNameDirExtSet( "q" + lower( hb_FNameName( cSrc ) ), hbmk2[ "cWorkDir" ], ".h" ) )
            cDst := hbmk2_FNameDirExtSet( "moc_q" + lower( hb_FNameName( cSrc ) ), hbmk2[ "cWorkDir" ], ".cpp" )
            AAdd( hbmk2[ "vars" ][ "aMOC_Dst" ], cDst )
            hbmk2_AddInput_CPP( hbmk2, cDst )
         ENDIF
      NEXT

      /* Detect tool locations */

      IF ! hbmk2[ "lCLEAN" ]
         IF ! Empty( hbmk2[ "vars" ][ "aQRC_Src" ] )
            hbmk2[ "vars" ][ "cRCC_BIN" ] := qt_tool_detect( hbmk2, "rcc", "RCC_BIN", .F. )
            IF Empty( hbmk2[ "vars" ][ "cRCC_BIN" ] )
               cRetVal := I_( "Required QT tool not found" )
            ENDIF
         ENDIF
         IF ! Empty( hbmk2[ "vars" ][ "aUIC_Src" ] )
            hbmk2[ "vars" ][ "cUIC_BIN" ] := qt_tool_detect( hbmk2, "uic", "UIC_BIN" )
            IF Empty( hbmk2[ "vars" ][ "cUIC_BIN" ] )
               cRetVal := I_( "Required QT tool not found" )
            ENDIF
         ENDIF
         IF ! Empty( hbmk2[ "vars" ][ "aMOC_Src" ] )
            hbmk2[ "vars" ][ "cMOC_BIN" ] := qt_tool_detect( hbmk2, "moc", "MOC_BIN" )
            IF Empty( hbmk2[ "vars" ][ "cMOC_BIN" ] )
               cRetVal := I_( "Required QT tool not found" )
            ENDIF
         ENDIF
      ENDIF

      EXIT

   CASE "pre_prg"

      IF ! hbmk2[ "lCLEAN" ] .AND. ;
         ! Empty( hbmk2[ "vars" ][ "aQRC_Src" ] )

         IF ! Empty( hbmk2[ "vars" ][ "cRCC_BIN" ] )

            /* Execute 'rcc' commands on input files */

            FOR EACH cSrc, cDst, cPRG IN hbmk2[ "vars" ][ "aQRC_Src" ], hbmk2[ "vars" ][ "aQRC_Dst" ], hbmk2[ "vars" ][ "aQRC_PRG" ]

               IF hbmk2[ "lINC" ] .AND. ! hbmk2[ "lREBUILD" ]
                  lBuildIt := ! hb_FGetDateTime( cDst, @tDst ) .OR. ;
                              ! hb_FGetDateTime( cSrc, @tSrc ) .OR. ;
                              tSrc > tDst
               ELSE
                  lBuildIt := .T.
               ENDIF

               IF lBuildIt

                  cCommand := hbmk2[ "vars" ][ "cRCC_BIN" ] +;
                              " -binary" +;
                              " " + hbmk2_FNameEscape( hbmk2_PathSepToTarget( hbmk2, cSrc ), hbmk2[ "nCmd_Esc" ], hbmk2[ "nCmd_FNF" ] ) +;
                              " -o " + hbmk2_FNameEscape( hbmk2_PathSepToTarget( hbmk2, cDst ), hbmk2[ "nCmd_Esc" ], hbmk2[ "nCmd_FNF" ] )

                  IF hbmk2[ "lTRACE" ]
                     IF ! hbmk2[ "lQUIET" ]
                        hbmk2_OutStd( hbmk2, I_( "'rcc' command:" ) )
                     ENDIF
                     hbmk2_OutStdRaw( cCommand )
                  ENDIF

                  IF ! hbmk2[ "lDONTEXEC" ]
                     IF ( nError := hb_processRun( cCommand ) ) != 0
                        hbmk2_OutErr( hbmk2, hb_StrFormat( I_( "Error: Running 'rcc' executable. %1$s" ), hb_ntos( nError ) ) )
                        IF ! hbmk2[ "lQUIET" ]
                           hbmk2_OutErrRaw( cCommand )
                        ENDIF
                        IF ! hbmk2[ "lIGNOREERROR" ]
                           cRetVal := "error"
                           EXIT
                        ENDIF
                     ELSE
                        /* Create little .prg stub which includes the binary */
                        cTmp := "/* WARNING: Automatically generated source file. DO NOT EDIT! */" + hb_eol() +;
                                hb_eol() +;
                                "#pragma -km+" + hb_eol() +;
                                hb_eol() +;
                                "FUNCTION hbqtres_" + hbmk2_FNameToSymbol( hb_FNameName( cSrc ) ) + "()" + hb_eol() +;
                                "   #pragma __binarystreaminclude " + Chr( 34 ) + hb_FNameNameExt( cDst ) + Chr( 34 ) + " | RETURN %s" + hb_eol()

                        IF ! hb_MemoWrit( cPRG, cTmp )
                           hbmk2_OutErr( hbmk2, hb_StrFormat( "Error: Cannot create file: %1$s", cPRG ) )
                           IF ! hbmk2[ "lIGNOREERROR" ]
                              cRetVal := "error"
                              EXIT
                           ENDIF
                        ENDIF
                     ENDIF
                  ENDIF
               ENDIF
            NEXT
         ENDIF
      ENDIF

      IF ! hbmk2[ "lCLEAN" ] .AND. ;
         ! Empty( hbmk2[ "vars" ][ "aUIC_Src" ] )

         IF ! Empty( hbmk2[ "vars" ][ "cUIC_BIN" ] )

            /* Execute 'uic' commands on input files */

            FOR EACH cSrc, cDst IN hbmk2[ "vars" ][ "aUIC_Src" ], hbmk2[ "vars" ][ "aUIC_Dst" ]

               IF hbmk2[ "lINC" ] .AND. ! hbmk2[ "lREBUILD" ]
                  lBuildIt := ! hb_FGetDateTime( cDst, @tDst ) .OR. ;
                              ! hb_FGetDateTime( cSrc, @tSrc ) .OR. ;
                              tSrc > tDst
               ELSE
                  lBuildIt := .T.
               ENDIF

               IF lBuildIt

                  FClose( hb_FTempCreateEx( @cTmp ) )

                  cCommand := hbmk2[ "vars" ][ "cUIC_BIN" ] +;
                              " " + hbmk2_FNameEscape( hbmk2_PathSepToTarget( hbmk2, cSrc ), hbmk2[ "nCmd_Esc" ], hbmk2[ "nCmd_FNF" ] ) +;
                              " -o " + hbmk2_FNameEscape( cTmp, hbmk2[ "nCmd_Esc" ], hbmk2[ "nCmd_FNF" ] )

                  IF hbmk2[ "lTRACE" ]
                     IF ! hbmk2[ "lQUIET" ]
                        hbmk2_OutStd( hbmk2, I_( "'uic' command:" ) )
                     ENDIF
                     hbmk2_OutStdRaw( cCommand )
                  ENDIF

                  IF ! hbmk2[ "lDONTEXEC" ]
                     IF ( nError := hb_processRun( cCommand ) ) != 0
                        hbmk2_OutErr( hbmk2, hb_StrFormat( I_( "Error: Running 'uic' executable. %1$s" ), hb_ntos( nError ) ) )
                        IF ! hbmk2[ "lQUIET" ]
                           hbmk2_OutErrRaw( cCommand )
                        ENDIF
                        IF ! hbmk2[ "lIGNOREERROR" ]
                           FErase( cTmp )
                           cRetVal := "error"
                           EXIT
                        ENDIF
                     ELSE
                        IF ! uic_to_prg( hbmk2, cTmp, cDst, hbmk2_FNameToSymbol( hb_FNameName( cSrc ) ) )
                           IF ! hbmk2[ "lIGNOREERROR" ]
                              FErase( cTmp )
                              cRetVal := "error"
                              EXIT
                           ENDIF
                        ENDIF
                     ENDIF
                  ENDIF
                  FErase( cTmp )
               ENDIF
            NEXT
         ENDIF
      ENDIF

      EXIT

   CASE "pre_c"

      IF ! hbmk2[ "lCLEAN" ] .AND. ;
         ! Empty( hbmk2[ "vars" ][ "aQTH_Src" ] )

         IF ! Empty( hbmk2[ "vars" ][ "qtmodule" ] ) .AND. ;
            ! Empty( hbmk2[ "vars" ][ "qtver" ] )

            FOR EACH cSrc, cDstCPP, cDstDOC IN hbmk2[ "vars" ][ "aQTH_Src" ], hbmk2[ "vars" ][ "aQTH_CPP" ], hbmk2[ "vars" ][ "aQTH_DOC" ]

               IF hbmk2[ "lINC" ] .AND. ! hbmk2[ "lREBUILD" ]
                  lBuildIt := ! hb_FGetDateTime( cDstCPP, @tDstCPP ) .OR. ;
                              ! hb_FGetDateTime( cSrc, @tSrc ) .OR. ;
                              tSrc > tDstCPP
               ELSE
                  lBuildIt := .T.
               ENDIF

               IF lBuildIt
                  IF ! hbmk2[ "lDONTEXEC" ]
                     IF ! qth_to_src( cSrc, cDstCPP, cDstDOC, hbmk2[ "vars" ][ "qtmodule" ], hbmk2[ "vars" ][ "qtver" ] )
                        IF ! hbmk2[ "lIGNOREERROR" ]
                           cRetVal := "error"
                           EXIT
                        ENDIF
                     ENDIF
                  ENDIF
               ENDIF
            NEXT
         ELSE
            hbmk2_OutErr( hbmk2, I_( "Error: Qt module or version not specified." ) )
            cRetVal := "error"
         ENDIF
      ENDIF

      IF ! hbmk2[ "lCLEAN" ] .AND. ;
         ! Empty( hbmk2[ "vars" ][ "aMOC_Src" ] )

         IF ! Empty( hbmk2[ "vars" ][ "cMOC_BIN" ] )

            /* Execute 'moc' commands on input files */

            FOR EACH cSrc, cDst IN hbmk2[ "vars" ][ "aMOC_Src" ], hbmk2[ "vars" ][ "aMOC_Dst" ]

               IF hbmk2[ "lINC" ] .AND. ! hbmk2[ "lREBUILD" ]
                  lBuildIt := ! hb_FGetDateTime( cDst, @tDst ) .OR. ;
                              ! hb_FGetDateTime( cSrc, @tSrc ) .OR. ;
                              tSrc > tDst
               ELSE
                  lBuildIt := .T.
               ENDIF

               IF lBuildIt

                  cCommand := hbmk2[ "vars" ][ "cMOC_BIN" ] +;
                              " " + hbmk2_FNameEscape( hbmk2_PathSepToTarget( hbmk2, cSrc ), hbmk2[ "nCmd_Esc" ], hbmk2[ "nCmd_FNF" ] ) +;
                              " -o " + hbmk2_FNameEscape( hbmk2_PathSepToTarget( hbmk2, cDst ), hbmk2[ "nCmd_Esc" ], hbmk2[ "nCmd_FNF" ] )

                  IF hbmk2[ "lTRACE" ]
                     IF ! hbmk2[ "lQUIET" ]
                        hbmk2_OutStd( hbmk2, I_( "'moc' command:" ) )
                     ENDIF
                     hbmk2_OutStdRaw( cCommand )
                  ENDIF

                  IF ! hbmk2[ "lDONTEXEC" ] .AND. ( nError := hb_processRun( cCommand ) ) != 0
                     hbmk2_OutErr( hbmk2, hb_StrFormat( I_( "Error: Running 'moc' executable. %1$s" ), hb_ntos( nError ) ) )
                     IF ! hbmk2[ "lQUIET" ]
                        hbmk2_OutErrRaw( cCommand )
                     ENDIF
                     IF ! hbmk2[ "lIGNOREERROR" ]
                        cRetVal := "error"
                        EXIT
                     ENDIF
                  ENDIF
               ENDIF
            NEXT
         ENDIF
      ENDIF

      EXIT

   CASE "post_all"

      IF ! hbmk2[ "lINC" ] .OR. hbmk2[ "lCLEAN" ]
         AEval( hbmk2[ "vars" ][ "aQRC_Dst" ], {| tmp | FErase( tmp ) } )
         AEval( hbmk2[ "vars" ][ "aQRC_PRG" ], {| tmp | FErase( tmp ) } )
         AEval( hbmk2[ "vars" ][ "aUIC_Dst" ], {| tmp | FErase( tmp ) } )
         AEval( hbmk2[ "vars" ][ "aMOC_Dst" ], {| tmp | FErase( tmp ) } )
         AEval( hbmk2[ "vars" ][ "aQTH_CPP" ], {| tmp | FErase( tmp ) } )
         AEval( hbmk2[ "vars" ][ "aQTH_DOC" ], {| tmp | FErase( tmp ) } )
      ENDIF

      EXIT

   ENDSWITCH

   RETURN cRetVal

STATIC FUNCTION qt_tool_detect( hbmk2, cName, cEnvQT, lPostfix )
   LOCAL cBIN
   LOCAL aEnvList
   LOCAL cStdErr

   IF ! hb_isLogical( lPostfix )
      lPostfix := .T.
   ENDIF

   IF lPostfix
      aEnvList := { "HB_QTPATH", "HB_QTPOSTFIX" }
   ELSE
      aEnvList := { "HB_QTPATH" }
   ENDIF

   cBIN := GetEnv( cEnvQT )
   IF Empty( cBIN )

      IF lPostfix
         cName += GetEnv( "HB_QTPOSTFIX" )
      ENDIF
      cName += hbmk2[ "cCCEXT" ]

      IF Empty( GetEnv( "HB_QTPATH" ) ) .OR. ;
         ! hb_FileExists( cBIN := hb_DirSepAdd( GetEnv( "HB_QTPATH" ) ) + cName )

         #if defined( __PLATFORM__WINDOWS ) .OR. defined( __PLATFORM__OS2 )

            hb_AIns( aEnvList, 1, "HB_WITH_QT", .T. )

            IF ! Empty( GetEnv( "HB_WITH_QT" ) )

               IF GetEnv( "HB_WITH_QT" ) == "no"
                  /* Return silently. It shall fail at dependency detection inside hbmk2 */
                  RETURN NIL
               ELSE
                  IF ! hb_FileExists( cBIN := hb_PathNormalize( hb_DirSepAdd( GetEnv( "HB_WITH_QT" ) ) + "..\bin\" + cName ) )
                     hbmk2_OutErr( hbmk2, hb_StrFormat( "Warning: HB_WITH_QT points to incomplete QT installation. '%1$s' executable not found.", cName ) )
                     cBIN := ""
                  ENDIF
               ENDIF
            ELSE
               cBIN := hb_DirSepAdd( hb_DirBase() ) + cName
               IF ! hb_FileExists( cBIN )
                  cBIN := ""
               ENDIF
            ENDIF
         #else
            cBIN := ""
         #endif

         IF Empty( cBIN )
            cBIN := hbmk2_FindInPath( cName, GetEnv( "PATH" ) + hb_osPathListSeparator() + "/opt/qtsdk/qt/bin" )
            IF Empty( cBIN )
               hbmk2_OutErr( hbmk2, hb_StrFormat( "%1$s not set, could not autodetect '%2$s' executable", hbmk2_ArrayToList( aEnvList, ", " ), cName ) )
               RETURN NIL
            ENDIF
         ENDIF
      ENDIF
      IF hbmk2[ "lINFO" ]
         cStdErr := ""
         IF ! hbmk2[ "lDONTEXEC" ]
            hb_processRun( cBIN + " -v",,, @cStdErr )
            IF ! Empty( cStdErr )
               cStdErr := " [" + StrTran( StrTran( cStdErr, Chr( 13 ) ), Chr( 10 ) ) + "]"
            ENDIF
         ENDIF
         hbmk2_OutStd( hbmk2, hb_StrFormat( "Using QT '%1$s' executable: %2$s%3$s (autodetected)", cName, cBIN, cStdErr ) )
      ENDIF
   ENDIF

   RETURN cBIN

#else

/* Standalone test code conversions */
PROCEDURE Main( cSrc )
   LOCAL cTmp
   LOCAL nError
   LOCAL cExt
   LOCAL aFile
   LOCAL cFN

   IF cSrc != NIL

      hb_FNameSplit( cSrc,,, @cExt )

      SWITCH Lower( cExt )
      CASE ".ui"

         FClose( hb_FTempCreateEx( @cTmp ) )

         IF ( nError := hb_processRun( "uic " + cSrc + " -o " + cTmp ) ) == 0
            IF ! uic_to_prg( NIL, cTmp, cSrc + ".prg", "TEST" )
               nError := 9
            ENDIF
         ELSE
            OutErr( "Error: Calling 'uic' tool: " + hb_ntos( nError ) + hb_eol() )
         ENDIF

         FErase( cTmp )
         EXIT

      CASE ".qth"

         FOR EACH aFile IN Directory( cSrc )
            cFN := hb_FNameMerge( FNameDirGet( cSrc ), aFile[ F_NAME ] )
            qth_to_src( cFN, cFN + ".cpp", cFN + ".txt", "QtModule", "0x040500" )
         NEXT

         EXIT

      ENDSWITCH
   ELSE
      OutErr( "Missing parameter. Call with: <input>" + hb_eol() )
      nError := 8
   ENDIF

   ErrorLevel( nError )

   RETURN

STATIC FUNCTION FNameDirGet( cFileName )
   LOCAL cDir

   hb_FNameSplit( cFileName, @cDir )

   RETURN cDir

STATIC FUNCTION hbmk2_OutStd( hbmk2, ... )
   HB_SYMBOL_UNUSED( hbmk2 )
   RETURN OutStd( ... )

STATIC FUNCTION hbmk2_OutErr( hbmk2, ... )
   HB_SYMBOL_UNUSED( hbmk2 )
   RETURN OutErr( ... )

#endif

/* ----------------------------------------------------------------------- */

STATIC FUNCTION uic_to_prg( hbmk2, cFileNameSrc, cFileNameDst, cName )
   LOCAL aLinesPRG
   LOCAL cFile

   IF hb_FileExists( cFileNameSrc )
      IF ! Empty( cFile := hb_MemoRead( cFileNameSrc ) )
         IF ! Empty( aLinesPRG := hbqtui_gen_prg( cFile, "hbqtui_" + cName ) )
            cFile := ""
            AEval( aLinesPRG, {| cLine | cFile += cLine + hb_eol() } )
            IF hb_MemoWrit( cFileNameDst, cFile )
               RETURN .T.
            ELSE
               hbmk2_OutErr( hbmk2, hb_StrFormat( "Error: Cannot create file: %1$s", cFileNameDst ) )
            ENDIF
         ELSE
            hbmk2_OutErr( hbmk2, hb_StrFormat( "Error: Intermediate file (%1$s) is not an .uic file.", cFileNameSrc ) )
         ENDIF
      ELSE
         hbmk2_OutErr( hbmk2, hb_StrFormat( "Error: Intermediate file (%1$s) empty or cannot be read.", cFileNameSrc ) )
      ENDIF
   ELSE
      hbmk2_OutErr( hbmk2, hb_StrFormat( "Error: Cannot find intermediate file: %1$s", cFileNameSrc ) )
   ENDIF

   RETURN .F.

/* ----------------------------------------------------------------------- */

#define HBQTUI_STRINGIFY( cStr )    '"' + cStr + '"'
#define HBQTUI_PAD_30( cStr )       PadR( cStr, Max( Len( cStr ), 35 ) )
#define HBQTUI_STRIP_SQ( cStr )     StrTran( StrTran( StrTran( StrTran( s, "[", " " ), "]", " " ), "\n", " " ), Chr( 10 ), " " )

STATIC FUNCTION hbqtui_gen_prg( cFile, cFuncName )
   LOCAL s
   LOCAL n
   LOCAL n1
   LOCAL cCls
   LOCAL cNam
   LOCAL lCreateFinished
   LOCAL cMCls
   LOCAL cMNam
   LOCAL cText
   LOCAL cCmd
   LOCAL aReg
   LOCAL item
   LOCAL aLinesPRG

   LOCAL regEx := hb_regexComp( "\bQ[A-Za-z_]+ \b" )

   LOCAL aLines := hb_ATokens( StrTran( cFile, Chr( 13 ) ), Chr( 10 ) )

   LOCAL aWidgets := {}
   LOCAL aCommands := {}

   lCreateFinished := .F.

   /* Pullout the widget */
   n := AScan( aLines, {| e | "void setupUi" $ e } )
   IF n == 0
      RETURN NIL
   ENDIF
   s     := AllTrim( aLines[ n ] )
   n     := At( "*", s )
   cMCls := AllTrim( SubStr( s, 1, n - 1 ) )
   cMNam := AllTrim( SubStr( s, n + 1 ) )
   hbqtui_stripFront( @cMCls, "(" )
   hbqtui_stripRear( @cMNam, ")" )

   AAdd( aWidgets, { cMCls, cMNam, cMCls + "()", cMCls + "()" } )

   /* Normalize */
   FOR EACH s IN aLines
      s := AllTrim( s )
      IF Right( s, 1 ) == ";"
         s := SubStr( s, 1, Len( s ) - 1 )
      ENDIF
      IF Left( s, 1 ) $ "/,*,{,}"
         s := ""
      ENDIF
   NEXT

   FOR EACH s IN aLines

      IF ! Empty( s )

         /* Replace Qt::* with actual values */
         hbqtui_replaceConstants( @s )

         IF "setupUi" $ s
            lCreateFinished := .T.

         ELSEIF Left( s, 1 ) == "Q" .AND. ! lCreateFinished .AND. ( n := At( "*", s ) ) > 0
            // We will deal later - just skip

         ELSEIF hbqtui_notAString( s ) .AND. ! Empty( aReg := hb_regex( regEx, s ) )
            cCls := RTrim( aReg[ 1 ] )
            s := AllTrim( StrTran( s, cCls, "",, 1 ) )
            IF ( n := At( "(", s ) ) > 0
               cNam := SubStr( s, 1, n - 1 )
               AAdd( aWidgets, { cCls, cNam, cCls + "()", cCls + SubStr( s, n ) } )
            ELSE
               cNam := s
               AAdd( aWidgets, { cCls, cNam, cCls + "()", cCls + "()" } )
            ENDIF

         ELSEIF hbqtui_isObjectNameSet( s )
            // Skip - we already know the object name and will set after construction

         ELSEIF ! Empty( cText := hbqtui_pullSetToolTip( aLines, s:__enumIndex() ) )
            n := At( "->", cText )
            cNam := AllTrim( SubStr( cText, 1, n - 1 ) )
            cCmd := hbqtui_formatCommand( SubStr( cText, n + 2 ), .T., aWidgets )
            AAdd( aCommands, { cNam, cCmd } )

         ELSEIF ! Empty( cText := hbqui_pullText( aLines, s:__enumIndex() ) )
            n := At( "->", cText )
            cNam := AllTrim( SubStr( cText, 1, n - 1 ) )
            cCmd := hbqtui_formatCommand( SubStr( cText, n + 2 ), .T., aWidgets )
            AAdd( aCommands, { cNam, cCmd } )

         ELSEIF hbqtui_isValidCmdLine( s ) .AND. !( "->" $ s ) .AND. ( ( n := At( ".", s ) ) > 0  )  /* Assignment to objects on stack */
            cNam := SubStr( s, 1, n - 1 )
            cCmd := SubStr( s, n + 1 )
            cCmd := hbqtui_formatCommand( cCmd, .F., aWidgets )
            cCmd := hbqtui_setObjects( cCmd, aWidgets )
            cCmd := hbqtui_setObjects( cCmd, aWidgets )
            AAdd( aCommands, { cNam, cCmd } )

         ELSEIF !( Left( s, 1 ) $ '#/*"' ) .AND. ;          /* Assignment with properties from objects */
                        ( n := At( ".", s ) ) > 0 .AND. ;
                        At( "->", s ) > n
            cNam := SubStr( s, 1, n - 1 )
            cCmd := SubStr( s, n + 1 )
            cCmd := hbqtui_formatCommand( cCmd, .F., aWidgets )
            cCmd := hbqtui_setObjects( cCmd, aWidgets )
            cCmd := hbqtui_setObjects( cCmd, aWidgets )
            AAdd( aCommands, { cNam, cCmd } )

         ELSEIF ( n := At( "->", s ) ) > 0                  /* Assignments or calls to objects on heap */
            cNam := SubStr( s, 1, n - 1 )
            cCmd := hbqtui_formatCommand( SubStr( s, n + 2 ), .F., aWidgets )
            cCmd := hbqtui_setObjects( cCmd, aWidgets )
            AAdd( aCommands, { cNam, cCmd } )

         ELSEIF ( n := At( "= new", s ) ) > 0
            IF ( n1 := At( "*", s ) ) > 0 .AND. n1 < n
               s := AllTrim( SubStr( s, n1 + 1 ) )
            ENDIF
            n    := At( "= new", s )
            cNam := AllTrim( SubStr( s, 1, n - 1 ) )
            cCmd := AllTrim( SubStr( s, n + Len( "= new" ) ) )
            cCmd := hbqtui_setObjects( cCmd, aWidgets )
            n := At( "(", cCmd )
            cCls := SubStr( cCmd, 1, n - 1 )
            AAdd( aWidgets, { cCls, cNam, cCls + "()", cCls + SubStr( cCmd, n ) } )

         ENDIF
      ENDIF
   NEXT

   aLinesPRG := {}

   AAdd( aLinesPRG, "/* WARNING: Automatically generated source file. DO NOT EDIT! */" )
   AAdd( aLinesPRG, "" )
   AAdd( aLinesPRG, '#include "hbqtgui.ch"' )

   AAdd( aLinesPRG, "" )
   AAdd( aLinesPRG, "FUNCTION " + cFuncName + "( qParent )" )
   AAdd( aLinesPRG, "   LOCAL oRootWidget" )
   AAdd( aLinesPRG, "   LOCAL hWidget := { => }" )
   AAdd( aLinesPRG, "" )
   AAdd( aLinesPRG, "   hb_hCaseMatch( hWidget, .F. )" )
   AAdd( aLinesPRG, "   hb_hKeepOrder( hWidget, .T. )" )
   AAdd( aLinesPRG, "" )

   SWITCH cMCls
   CASE "QDialog"
      AAdd( aLinesPRG, "   oRootWidget := QDialog( qParent )" )
      EXIT
   CASE "QWidget"
      AAdd( aLinesPRG, "   oRootWidget := QWidget( qParent )" )
      EXIT
   CASE "QMainWindow"
      AAdd( aLinesPRG, "   oRootWidget := QMainWindow( qParent )" )
      EXIT
   ENDSWITCH
   AAdd( aLinesPRG, "  " )
   AAdd( aLinesPRG, "   oRootWidget:setObjectName( " + HBQTUI_STRINGIFY( cMNam ) + " )" )
   AAdd( aLinesPRG, "  " )
   AAdd( aLinesPRG, "   hWidget[ " + HBQTUI_PAD_30( HBQTUI_STRINGIFY( cMNam ) ) + " ] := oRootWidget" )
   AAdd( aLinesPRG, "  " )

   FOR EACH item IN aWidgets
      IF item:__enumIndex() > 1
         AAdd( aLinesPRG, "   hWidget[ " + HBQTUI_PAD_30( HBQTUI_STRINGIFY( item[ 2 ] ) ) + " ] := " + StrTran( item[ 4 ], "o[", "hWidget[" ) )
      ENDIF
   NEXT
   AAdd( aLinesPRG, "" )

   FOR EACH item IN aCommands
      cNam := item[ 1 ]
      cCmd := item[ 2 ]
      cCmd := StrTran( cCmd, "true" , ".T." )
      cCmd := StrTran( cCmd, "false", ".F." )

      IF "addWidget" $ cCmd
         IF hbqtui_occurs( cCmd, "," ) >= 4
            cCmd := StrTran( cCmd, "addWidget", "addWidget" )
         ENDIF
      ELSEIF "addLayout" $ cCmd
         IF hbqtui_occurs( cCmd, "," ) >= 4
            cCmd := StrTran( cCmd, "addLayout", "addLayout" )
         ENDIF
      ENDIF

      IF "setToolTip(" $ cCmd
         s := hbqtui_pullToolTip( cCmd )
         AAdd( aLinesPRG, "   hWidget[ " + HBQTUI_PAD_30( HBQTUI_STRINGIFY( cNam ) ) + " ]:setToolTip( [" + HBQTUI_STRIP_SQ( s ) + "] )" )

      ELSEIF "setPlainText(" $ cCmd
         s := hbqtui_pullToolTip( cCmd )
         AAdd( aLinesPRG, "   hWidget[ " + HBQTUI_PAD_30( HBQTUI_STRINGIFY( cNam ) ) + " ]:setPlainText( [" + HBQTUI_STRIP_SQ( s ) + "] )" )

      ELSEIF "setStyleSheet(" $ cCmd
         s := hbqtui_pullToolTip( cCmd )
         AAdd( aLinesPRG, "   hWidget[ " + HBQTUI_PAD_30( HBQTUI_STRINGIFY( cNam ) ) + " ]:setStyleSheet( [" + HBQTUI_STRIP_SQ( s ) + "] )" )

      ELSEIF "setText(" $ cCmd
         s := hbqtui_pullToolTip( cCmd )
         IF hbqtui_pullColumn( cCmd, @n )
            AAdd( aLinesPRG, "   hWidget[ " + HBQTUI_PAD_30( HBQTUI_STRINGIFY( cNam ) ) + " ]:setText( " + hb_ntos( n ) + ", [" + HBQTUI_STRIP_SQ( s ) + "] )" )
         ELSE
            AAdd( aLinesPRG, "   hWidget[ " + HBQTUI_PAD_30( HBQTUI_STRINGIFY( cNam ) ) + " ]:setText( [" + HBQTUI_STRIP_SQ( s ) + "] )" )
         ENDIF

      ELSEIF "setWhatsThis(" $ cCmd
         s := hbqtui_pullToolTip( cCmd )
         AAdd( aLinesPRG, "   hWidget[ " + HBQTUI_PAD_30( HBQTUI_STRINGIFY( cNam ) ) + " ]:setWhatsThis( [" + HBQTUI_STRIP_SQ( s ) + "] )" )

      ELSEIF "header()->" $ cCmd
         // TODO: how to handle : __qtreeviewitem->header()->setVisible( .F. )

      ELSEIF cCmd == "pPtr"
         // Nothing TO DO

      ELSE
         AAdd( aLinesPRG, "   hWidget[ " + HBQTUI_PAD_30( HBQTUI_STRINGIFY( cNam ) ) + " ]:" + StrTran( cCmd, "o[", "hWidget[" ) )

      ENDIF
   NEXT
   AAdd( aLinesPRG, "" )
   AAdd( aLinesPRG, "   RETURN HbQtUI():new( oRootWidget, hWidget )" )
   AAdd( aLinesPRG, "" )

   RETURN aLinesPRG

STATIC FUNCTION hbqtui_formatCommand( cCmd, lText, widgets )
   LOCAL regDefine
   LOCAL aDefine
   LOCAL n
   LOCAL n1
   LOCAL cNam
   LOCAL cCmd1

   STATIC s_nn := 100

   IF lText == NIL
      lText := .T.
   ENDIF

   cCmd := StrTran( cCmd, "QApplication_translate"   , "q__tr"        )
   cCmd := StrTran( cCmd, "QApplication::UnicodeUTF8", '"UTF8"'       )
   cCmd := StrTran( cCmd, "QString()"                , '""'           )
   cCmd := StrTran( cCmd, "QSize("                   , "QSize(" )
   cCmd := StrTran( cCmd, "QRect("                   , "QRect(" )

   IF "::" $ cCmd
      regDefine := hb_regexComp( "\b[A-Za-z_]+\:\:[A-Za-z_]+\b" )
      aDefine := hb_regex( regDefine, cCmd )
      IF ! Empty( aDefine )
         cCmd := StrTran( cCmd, "::", "_" )    /* Qt Defines  - how to handle */
      ENDIF
   ENDIF

   IF ! lText .AND. At( ".", cCmd ) > 0
      // sizePolicy     setHeightForWidth(ProjectProperties->sizePolicy().hasHeightForWidth());
      //
      IF ( At( "setHeightForWidth(", cCmd ) ) > 0
         cNam := "__qsizePolicy" + hb_ntos( ++s_nn )
         n    := At( "(", cCmd )
         n1   := At( ".", cCmd )
         cCmd1 := hbqtui_setObjects( SubStr( cCmd, n + 1, n1 - n - 1 ), widgets )
         cCmd1 := StrTran( cCmd1, "->", ":" )
         AAdd( widgets, { "QSizePolicy", cNam, "QSizePolicy()", "QSizePolicy(" + cCmd1 + ")" } )
         cCmd := 'setHeightForWidth(o[ "' + cNam + '" ]:' + SubStr( cCmd, n1 + 1 )
      ELSE
         cCmd := "pPtr"
      ENDIF
   ENDIF

   RETURN cCmd

STATIC FUNCTION hbqtui_isObjectNameSet( cString )
   RETURN "objectName" $ cString .OR. ;
          "ObjectName" $ cString

STATIC FUNCTION hbqtui_isValidCmdLine( cString )
   RETURN !( Left( cString, 1 ) $ '#/*"' )

STATIC FUNCTION hbqtui_notAString( cString )
   RETURN !( Left( cString, 1 ) == '"' )

STATIC FUNCTION hbqtui_occurs( cString, cCharToFind )
   LOCAL cChar
   LOCAL nCount

   nCount := 0
   FOR EACH cChar IN cString
      IF cChar == cCharToFind
         ++nCount
      ENDIF
   NEXT

   RETURN nCount

STATIC FUNCTION hbqtui_pullColumn( cCmd, nCol )

   IF     "(0," $ cCmd
      nCol := 0; RETURN .T.
   ELSEIF "(1," $ cCmd
      nCol := 1; RETURN .T.
   ELSEIF "(2," $ cCmd
      nCol := 2; RETURN .T.
   ENDIF

   RETURN .F.

STATIC FUNCTION hbqtui_pullToolTip( cCmd )
   LOCAL n
   LOCAL cString := ""

   IF ( n := At( ', "', cCmd ) ) > 0
      cString := AllTrim( SubStr( cCmd, n + 2 ) )
      IF ( n := At( '", 0', cString ) ) > 0
         cString := AllTrim( SubStr( cString, 1, n ) )
         cString := StrTran( cString, '\"', '"' )
         cString := StrTran( cString, '""' )
         cString := SubStr( cString, 2, Len( cString ) - 2 )
      ENDIF
   ENDIF

   RETURN cString

STATIC PROCEDURE hbqtui_replaceConstants( /* @ */ cString )
   LOCAL aResult
   LOCAL cConst
   LOCAL cCmdB
   LOCAL cCmdE
   LOCAL cOR
   LOCAL n

   LOCAL regDefine := hb_regexComp( "\b[A-Za-z_]+\:\:[A-Za-z_]+\b" )

   IF hbqtui_occurs( cString, "|" ) > 0

      aResult := hb_regexAll( regDefine, cString )

      IF ! Empty( aResult )
         cOR := "hb_bitOr( "
         FOR n := 1 TO Len( aResult )
            cOR += aResult[ n ][ 1 ]
            IF n < Len( aResult )
               cOR += ","
            ENDIF
         NEXT
         cOR += " )"
         cCmdB   := SubStr( cString, 1, At( aResult[ 1 ][ 1 ], cString ) - 1 )
         cConst  := aResult[ Len( aResult ) ][ 1 ]
         cCmdE   := SubStr( cString, At( cConst, cString ) + Len( cConst ) )
         cString := cCmdB + cOR + cCmdE
      ENDIF
   ENDIF

   IF "::" $ cString
      DO WHILE .T.
         aResult := hb_regex( regDefine, cString )
         IF Empty( aResult )
            EXIT
         ENDIF
         cString := StrTran( cString, aResult[ 1 ], StrTran( aResult[ 1 ], "::", "_" ) )
      ENDDO
   ENDIF

   RETURN

STATIC FUNCTION hbqtui_setObjects( cCmd, aWidgets )
   LOCAL n
   LOCAL cObj

   IF ( n := AScan( aWidgets, {| tmp | ( tmp[ 2 ] + "," ) $ cCmd } ) ) > 0
      cObj := aWidgets[ n ][ 2 ]
      cCmd := StrTran( cCmd, cObj + ",", 'o[ "' + cObj + '" ],' )
   ENDIF

   IF ( n := AScan( aWidgets, {| tmp | ( tmp[ 2 ] + ")" ) $ cCmd } ) ) > 0
      cObj := aWidgets[ n ][ 2 ]
      cCmd := StrTran( cCmd, cObj + ")", 'o[ "' + cObj + '" ])' )
   ENDIF

   IF ( n := AScan( aWidgets, {| tmp | ( tmp[ 2 ] + "->" ) $ cCmd } ) ) > 0
      cObj := aWidgets[ n ][ 2 ]
      cCmd := StrTran( cCmd, cObj + "->", 'o[ "' + cObj + '" ]:' )
   ENDIF

   RETURN cCmd

STATIC FUNCTION hbqui_pullText( aLines, nFrom )
   LOCAL cString := ""
   LOCAL nLen := Len( aLines )
   LOCAL aKeyword := { "setText(", "setPlainText(", "setStyleSheet(", "setWhatsThis(" }

   IF AScan( aKeyword, {| tmp | tmp $ aLines[ nFrom ] } ) > 0
      cString := aLines[ nFrom ]
      nFrom++
      DO WHILE nFrom <= nLen
         IF !( Left( aLines[ nFrom ], 1 ) == '"' )
            EXIT
         ENDIF
         cString += aLines[ nFrom ]
         aLines[ nFrom ] := ""
         nFrom++
      ENDDO
   ENDIF

   RETURN cString

STATIC FUNCTION hbqtui_pullSetToolTip( aLines, nFrom )
   LOCAL cString := ""
   LOCAL nLen := Len( aLines )

   IF "#ifndef QT_NO_TOOLTIP" $ aLines[ nFrom ]
      nFrom++
      DO WHILE nFrom <= nLen
         IF "#endif // QT_NO_TOOLTIP" $ aLines[ nFrom ]
            EXIT
         ENDIF
         cString += aLines[ nFrom ]
         aLines[ nFrom ] := ""
         nFrom++
      ENDDO
   ENDIF

   RETURN cString

STATIC FUNCTION hbqtui_stripFront( /* @ */ cString, cTkn )
   LOCAL n
   LOCAL nLen := Len( cTkn )

   IF ( n := At( cTkn, cString ) ) > 0
      cString := SubStr( cString, n + nLen )
      RETURN .T.
   ENDIF

   RETURN .F.

STATIC FUNCTION hbqtui_stripRear( /* @ */ cString, cTkn )
   LOCAL n

   IF ( n := RAt( cTkn, cString ) ) > 0
      cString := SubStr( cString, 1, n - 1 )
      RETURN .T.
   ENDIF

   RETURN .F.

/*======================================================================*/

STATIC FUNCTION qth_to_src( cQTHFileName, cCPPFileName, cDOCFileName, cQtModule, cQtVer )
   LOCAL oSrc

   oSrc := HbQtSource():new( cQtModule, cQtVer, cQTHFileName, cCPPFileName, cDOCFileName )
   oSrc:build()

   RETURN .T.

/*----------------------------------------------------------------------*/

CREATE CLASS HbQtSource

   VAR    cCPPFileName, cDOCFileName
   VAR    hRef

   VAR    cQtModule
   VAR    cQtVer
   VAR    cQtObject

   VAR    aMethods                                INIT {}

   VAR    isList                                  INIT .F.
   VAR    isDestructor                            INIT .T.
   VAR    isConstructor                           INIT .F.
   VAR    isObject                                INIT .T.
   VAR    isDetached                              INIT .F.
   VAR    areMethodsClubbed                       INIT .T.

   VAR    class_                                  INIT {}
   VAR    subCls_                                 INIT {}
   VAR    docum_                                  INIT {}
   VAR    code_                                   INIT {}
   VAR    cls_                                    INIT {}
   VAR    new_                                    INIT {}
   VAR    newW_                                   INIT {}
   VAR    old_                                    INIT {}
   VAR    enums_                                  INIT {}
   VAR    enum_                                   INIT {}
   VAR    protos_                                 INIT {}
   VAR    varbls_                                 INIT {}
   VAR    slots_                                  INIT {}

   VAR    dummy_                                  INIT {}
   VAR    func_                                   INIT { { "", 0 } }
   VAR    txt_                                    INIT {}
   VAR    cmntd_                                  INIT {}
   VAR    doc_                                    INIT {}
   VAR    constructors_                           INIT {}

   VAR    nFuncs                                  INIT 0
   VAR    nCnvrtd                                 INIT 0

   VAR    cFunc
   VAR    cTrMode

   VAR    cInt                                    INIT "int,qint16,quint16,short,ushort,unsigned"
   VAR    cIntLong                                INIT "qint32,quint32,QRgb"
   VAR    cIntLongLong                            INIT "qint64,quint64,qlonglong,qulonglong,ulong"

   VAR    lPaintEvent                             INIT .f.
   VAR    lBuildExtended                          INIT .f.

   METHOD new( cQtModule, cQtVer, cQTHFileName, cCPPFileName, cDOCFileName )
   METHOD parseProto( cProto, fBody_ )
   METHOD parseVariables( cProto )
   METHOD build()
   METHOD exploreExtensions()
   METHOD buildExtendedSource( t_ )
   METHOD buildExtendedHeader()
   METHOD getConstructor()
   METHOD getConstructorW()
   METHOD buildCppCode( oMtd )
   METHOD buildMethodBody( oMtd )
   METHOD buildDOC()
   METHOD getMethodBody( oMtd, cMtdName, aMethods )
   METHOD normalizeCmd( oMtd, v )
   METHOD getReturnAsList( oMtd, FP, cPrefix )
   METHOD getReturnMethod( oMtd, lAddRet )

   ENDCLASS

/*----------------------------------------------------------------------*/

METHOD HbQtSource:new( cQtModule, cQtVer, cQTHFileName, cCPPFileName, cDOCFileName )
   LOCAL cQth, s, n, i, n1, b_, tmp, cOrg, fBody_
   LOCAL f

   ::hRef := { => }
   hb_HKeepOrder( ::hRef, .T. )

   IF Empty( GetEnv( "HBQT_BUILD_TR_LEVEL" ) )
      ::cTrMode := "HB_TR_DEBUG"
   ELSE
      ::cTrMode := Upper( GetEnv( "HBQT_BUILD_TR_LEVEL" ) )
      IF ! ( ::cTrMode $ "HB_TR_ALWAYS,HB_TR_WARNING,HB_TR_ERROR" )
         ::cTrMode := "HB_TR_DEBUG"
      ENDIF
   ENDIF

   hb_fNameSplit( cQTHFileName,, @tmp )

   ::cCPPFileName := cCPPFileName
   ::cDOCFileName := cDOCFileName

   ::cQtModule    := cQtModule
   ::cQtVer       := cQtVer

   ::cQtObject    := tmp

   cQth := hb_MemoRead( cQTHFileName )

   /* Prepare to be parsed properly */
   IF !( hb_eol() == Chr( 10 ) )
      cQth := StrTran( cQth, hb_eol(), Chr( 10 ) )
   ENDIF
   IF !( hb_eol() == Chr( 13 ) + Chr( 10 ) )
      cQth := StrTran( cQth, Chr( 13 ) + Chr( 10 ), Chr( 10 ) )
   ENDIF

   IF ! Empty( ::class_:= hbqtgen_PullOutSection( @cQth, "CLASS" ) )
      FOR EACH s IN ::class_
         IF ( n := at( "=", s ) ) > 0
            AAdd( ::cls_, { AllTrim( SubStr( s, 1, n - 1 ) ), AllTrim( SubStr( s, n + 1 ) ) } )
         ENDIF
      NEXT
   ENDIF

   /* Explore if protected methods are to be implemented */
   ::exploreExtensions()

   /* Reassign class level version information */
   IF ( n := AScan( ::cls_, {|e_| upper( e_[ 1 ] ) == "VERSION" } ) ) > 0
      IF ! Empty( ::cls_[ n, 2 ] )
         ::cQtVer := ::cls_[ n, 2 ]
      ENDIF
   ENDIF

   /* Pull out SUBCLASS section */
   ::subCls_ := hbqtgen_PullOutSection( @cQth, "SUBCLASS" )

   /* Pull out Doc Section */
   ::docum_  := hbqtgen_PullOutSection( @cQth, "DOC"   )

   /* Pull out Code Section */
   ::code_   := hbqtgen_PullOutSection( @cQth, "CODE"   )

   /* Separate constructor function */
   ::new_:= {}
   f := "HB_FUNC( QT_" + Upper( ::cQtObject ) + " )"
   ::cFunc := "HB_FUNC_STATIC( NEW )"

   n := AScan( ::code_, {| e | f $ e } )

   AAdd( ::new_, ::cFunc )
   FOR i := n + 1 TO Len( ::code_ )
      AAdd( ::new_, ::code_[ i ] )
      IF RTrim( ::code_[ i ] ) == "}"
         n1 := i
         EXIT
      ENDIF
   NEXT
   ::old_ :={}
   FOR i := 1 TO Len( ::code_ )
      IF i < n .or. i > n1
         AAdd( ::old_, ::code_[ i ] )
      ENDIF
   NEXT
   ::code_ := ::old_

   ::newW_:= aClone( ::new_ )
   ::newW_[ 1 ] := "HB_FUNC( " + Upper( ::cQtObject ) + " )"

   /* Pullout constructor methods */
   #if 0
   tmp := ::cQtObject + " ("
   FOR EACH s IN ::code_
      IF ( n := at( tmp, s ) ) > 0 .AND. ! ( "~" $ s )
         AAdd( ::constructors_, SubStr( s, n ) )
      ENDIF
   NEXT
   #endif

   /* Pull out Enumerators  */
   ::enums_:= hbqtgen_PullOutSection( @cQth, "ENUMS"  )
   ::enum_:= {}
   FOR EACH s IN ::enums_
      IF "enum " $ s .OR. "flags " $ s
         b_:= hb_ATokens( AllTrim( s ), " " )
         AAdd( ::enum_, b_[ 2 ] )
      ENDIF
   NEXT

   /* Pull out Prototypes   */
//   ::protos_ := hbqtgen_PullOutSection( @cQth, "PROTOS" )
   tmp := hbqtgen_PullOutSection( @cQth, "PROTOS" )
   AEval( ::constructors_, {| e | AAdd( ::protos_, e ) } )
   AEval( tmp, {| e | AAdd( ::protos_, e ) } )

   IF ::lBuildExtended
      AAdd( ::protos_, "void hbSetEventBlock( int event, PHB_ITEM block );" )
   ENDIF

   /* Pull out Variables */
   ::varbls_ := hbqtgen_PullOutSection( @cQth, "VARIABLES" )

   /* Pull Out Signals      */
   ::slots_  := hbqtgen_PullOutSection( @cQth, "SLOTS"  )

   /* Combine signals and protos : same nature */
   AEval( ::slots_, {| e | AAdd( ::protos_, e ) } )

   ::isList            := AScan( ::cls_, {| e_ | Lower( e_[ 1 ] ) == "list"        .AND. Lower( e_[ 2 ] ) == "yes" } ) > 0
   ::isDetached        := AScan( ::cls_, {| e_ | Lower( e_[ 1 ] ) == "detached"    .AND. Lower( e_[ 2 ] ) == "yes" } ) > 0
   ::isConstructor     := AScan( ::cls_, {| e_ | Lower( e_[ 1 ] ) == "constructor" .AND. Lower( e_[ 2 ] ) == "no"  } ) == 0
   ::isDestructor      := AScan( ::cls_, {| e_ | Lower( e_[ 1 ] ) == "destructor"  .AND. Lower( e_[ 2 ] ) == "no"  } ) == 0
   ::isObject          := AScan( ::cls_, {| e_ | Lower( e_[ 1 ] ) == "qobject"     .AND. Lower( e_[ 2 ] ) == "no"  } ) == 0
   ::areMethodsClubbed := AScan( ::cls_, {| e_ | Lower( e_[ 1 ] ) == "clubmethods" .AND. Lower( e_[ 2 ] ) == "no"  } ) == 0
   /* Determine Constructor - but this is hacky a bit. What could be easiest ? */
   IF ! ::isConstructor
      FOR i := 3 TO Len( ::new_ ) - 1
         IF !( Left( LTrim( ::new_[ i ] ), 2 ) == "//" )
            IF "__HB_RETPTRGC__(" $ ::new_[ i ]
               ::isConstructor := .T.
               EXIT
            ENDIF
         ENDIF
      NEXT
   ENDIF

   FOR EACH s IN ::protos_
      cOrg := s
      IF Empty( s := AllTrim( s ) )
         LOOP
      ENDIF

      /* Check if proto is commented out */
      IF Left( s, 2 ) == "//"
         AAdd( ::cmntd_, cOrg )
         LOOP
      ENDIF
      /* Check if it is not ANSI C Comment */
      IF Left( AllTrim( cOrg ), 1 ) $ "/*"
         LOOP
      ENDIF
      /* Another comment tokens */
      IF Empty( s ) .or. Left( s, 1 ) $ "#;}"
         LOOP
      ENDIF

      ::nFuncs++

      fBody_:= {}
      IF right( s, 1 ) == "{"
         fBody_:= hbqtgen_PullOutFuncBody( ::protos_, s:__enumIndex() )
         s := SubStr( s, 1, Len( s ) - 1 )
      ENDIF
      IF ::parseProto( s, fBody_ )
         ::nCnvrtd++
      ELSE
         AAdd( ::dummy_, cOrg )
      ENDIF
   NEXT

   FOR EACH s IN ::varbls_
      cOrg := s

      IF Empty( s := AllTrim( s ) )
         LOOP
      ENDIF
      /* Check if proto is commented out */
      IF Left( s, 2 ) == "//"
         AAdd( ::cmntd_, cOrg )
         LOOP
      ENDIF
      /* Check if it is not ANSI C Comment */
      IF Left( AllTrim( cOrg ), 1 ) $ "/*"
         LOOP
      ENDIF
      /* Another comment tokens */
      IF Empty( s ) .or. Left( s, 1 ) $ "#;"
         LOOP
      ENDIF

      ::nFuncs++

      IF ::parseVariables( s )
         ::nCnvrtd++
      ELSE
         AAdd( ::dummy_, cOrg )
      ENDIF
   NEXT

   RETURN Self

/*----------------------------------------------------------------------*/

METHOD HbQtSource:build()
   LOCAL i, s, oMtd, tmp, tmp1, n, k, aLine, uQtObject
   LOCAL cObjPfx := iif( ::lBuildExtended, "Q", "" )

   uQtObject := Upper( ::cQtObject )

   ::hRef[ ::cQtObject ] := NIL

   /* Methods Body */
   FOR EACH oMtd IN ::aMethods
      ::buildMethodBody( oMtd, ::aMethods )
   NEXT

   /* Pull .cpp copyright text */
   aLine := hbqtgen_BuildCopyrightText()

   /* Place ENUM definitions into the source */
   IF ! Empty( ::enums_ )
      AAdd( aLine, "/*" )
      AEval( ::enums_, {| e | iif( ! Empty( e ), AAdd( aLine, " *  " + e ), NIL ) } )
      AAdd( aLine, " */ " )
      AAdd( aLine, "" )
   ENDIF

   /* Insert information about prototypes not converted to functions */
#if 0
   AAdd( aLine, "/*" )
   AAdd( aLine, " *  Constructed[ " + hb_ntos( ::nCnvrtd ) + "/" + hb_ntos( ::nFuncs ) + " [ " + hb_ntos( ::nCnvrtd / ::nFuncs * 100 ) + "% ] ]" )
   AAdd( aLine, " *  " )
   IF ! Empty( ::dummy_ )
      AAdd( aLine, " *  *** Unconvered Prototypes ***" )
      AAdd( aLine, " *  " )
      AEval( ::dummy_, {| e | AAdd( aLine, " *  " + e ) } )
   ENDIF
   IF ! Empty( ::cmntd_ )
      AAdd( aLine, " *  " )
      AAdd( aLine, " *  " + "*** Commented out prototypes ***" )
      AAdd( aLine, " *  " )
      AEval( ::cmntd_, {| e | AAdd( aLine, " *  " + e ) } )
   ENDIF
   AAdd( aLine, " */ " )
   AAdd( aLine, "" )
#endif

   IF ::isConstructor
      FOR i := 3 TO Len( ::new_ ) - 1
         IF !( Left( LTrim( ::new_[ i ] ), 2 ) == "//" )
            IF "__HB_RETPTRGC__(" $ ::new_[ i ]
               tmp1 := ::new_[ i ]
               DO WHILE ( tmp := At( "hbqt_par_", tmp1 ) ) > 0
                  tmp1 := SubStr( tmp1, tmp + Len( "hbqt_par_" ) )
                  hbqtgen_AddRef( ::hRef, Left( tmp1, At( "(", tmp1 ) - 1 ) )
                  tmp1 := SubStr( tmp1, At( "(", tmp1 ) + 1 )
               ENDDO
            ENDIF
         ENDIF
      NEXT
   ENDIF

   /*----------------------------------------------------------------------*/
   /* Generate necessary declarations */

   AAdd( aLine, "HB_EXTERN_BEGIN" )
   AAdd( aLine, "" )
   AAdd( aLine, "HB_FUNC_EXTERN( __HB" + Upper( ::cQtModule ) + " );" )
   FOR EACH s IN ::hRef
      IF ! ( s:__enumKey() == "QModelIndexList" )
         AAdd( aLine, "HB_FUNC_EXTERN( HB_" + Upper( s:__enumKey() ) + " );" )
      ENDIF
   NEXT
   AAdd( aLine, "" )
   AAdd( aLine, "void _hb_force_link_" + ::cQtObject +"( void )" )
   AAdd( aLine, "{" )
   AAdd( aLine, "   HB_FUNC_EXEC( __HB" + Upper( ::cQtModule ) + " );" )
   FOR EACH s IN ::hRef
      IF ! ( s:__enumKey() == "QModelIndexList" )
         AAdd( aLine, "   HB_FUNC_EXEC( HB_" + Upper( s:__enumKey() ) + " );" )
      ENDIF
   NEXT
   AAdd( aLine, "}" )
   AAdd( aLine, "" )
   IF ::cQtVer > "0x040500"
      AAdd( aLine, "#if QT_VERSION >= " + ::cQtVer )
   ENDIF
   FOR EACH s IN ::hRef
      AAdd( aLine, "extern HB_EXPORT HBQT_GC_FUNC( hbqt_gcRelease_" + s:__enumKey() + " );" )
   NEXT
   AAdd( aLine, "" )
   FOR EACH s IN ::hRef
      AAdd( aLine, "extern HB_EXPORT void * hbqt_gcAllocate_" + s:__enumKey() + "( void * pObj, bool bNew );" )
   NEXT

   n := AScan( ::cls_, {| e_ | Left( Lower( e_[ 1 ] ), 7 ) == "inherit" .and. ! Empty( e_[ 2 ] ) } )
   IF n > 0
      s := Upper( StrTran( ::cls_[ n, 2 ], "Q", "HB_Q" ) )
   ELSE
      s := "HBQTOBJECTHANDLER"
   ENDIF
   
   AAdd( aLine, "" )   
   AAdd( aLine, "extern HB_EXPORT void hbqt_register_" + lower( uQtObject ) + "();" )      
   AAdd( aLine, "" )   
   
   FOR EACH k IN hb_aTokens( s, "," )
      k := lower( AllTrim( k ) )
      IF k == "hbqtobjecthandler"
         AAdd( aLine, "HB_FUNC_EXTERN( " + Upper( k ) + " );" )
      ELSE    
         AAdd( aLine, "extern HB_EXPORT void hbqt_register_" + substr( k,4 ) + "();" )
      ENDIF    
   NEXT
   AAdd( aLine, "" )
      
   IF ::cQtVer > "0x040500"
      AAdd( aLine, "#endif" )
   ENDIF
   AAdd( aLine, "" )

   FOR EACH k IN hb_aTokens( s, "," )
      AAdd( aLine, "HB_FUNC_EXTERN( " + Upper( AllTrim( k ) ) + " );" )
   NEXT
   AAdd( aLine, "" )
   AAdd( aLine, "HB_EXTERN_END" )
   AAdd( aLine, "" )
   AAdd( aLine, "static void s_registerMethods( HB_USHORT uiClass );" )
   AAdd( aLine, "" )
   AAdd( aLine, "static HB_CRITICAL_NEW( s_hbqtMtx );" )
   AAdd( aLine, "#define HB_HBQT_LOCK     hb_threadEnterCriticalSection( &s_hbqtMtx );" )
   AAdd( aLine, "#define HB_HBQT_UNLOCK   hb_threadLeaveCriticalSection( &s_hbqtMtx );" )
   AAdd( aLine, "" )
   IF ::cQtVer > "0x040500"
      AAdd( aLine, "#if QT_VERSION >= " + ::cQtVer )
   ENDIF
   FOR EACH s IN ::hRef
      IF s:__enumKey() == "QList" /* TOFIX: Ugly hack */
         tmp := s:__enumKey() + "< void * >"
      ELSEIF s:__enumKey() == "QModelIndexList" /* TOFIX: Ugly hack */
         tmp := "QList< QModelIndex >"
      ELSE
         tmp := s:__enumKey()
      ENDIF
      AAdd( aLine, PadR( "#define hbqt_par_" + s:__enumKey() + "( n )", 64 ) + PadR( "( ( " + tmp, 48 ) + "* ) hbqt_par_ptr( n ) )" )
   NEXT
   IF ::cQtVer > "0x040500"
      AAdd( aLine, "#endif" )
   ENDIF
   AAdd( aLine, "" )
   FOR EACH s IN ::hRef
      AAdd( aLine, PadR( "#define HBQT_TYPE_" + s:__enumKey(), 64 ) + "( ( HB_U32 ) 0x" + hb_NumToHex( hb_crc32( "HBQT_TYPE_" + s:__enumKey() ), 8 ) + " )" )
   NEXT
   AAdd( aLine, "" )
   /*----------------------------------------------------------------------*/

   /* Insert user defined code - INCLUDEs */
   AAdd( aLine, "#include <QtCore/QPointer>" )
   IF ! Empty( ::code_ )
      IF ::cQtVer > "0x040500"
         AAdd( aLine, "#if QT_VERSION >= " + ::cQtVer )
      ENDIF
      n := AScan( ::code_, {| e | "gcMark" $ e } )
      IF n == 0
         AEval( ::code_, {| e | AAdd( aLine, StrTran( e, chr( 13 ) ) ) } )
      ELSE
         AEval( ::code_, {| e | AAdd( aLine, StrTran( e, chr( 13 ) ) ) }, 1, n - 1 )
      ENDIF
      IF ::cQtVer > "0x040500"
         AAdd( aLine, "#endif" )
      ENDIF
      AAdd( aLine, "" )
   ENDIF

   ::buildExtendedSource( aLine )   /* Insert protected functions */

   IF ::cQtVer > "0x040500"
      AAdd( aLine, "#if QT_VERSION >= " + ::cQtVer )
   ENDIF
   AAdd( aLine, "typedef struct"                  )
   AAdd( aLine, "{"                               )
   IF ::isObject
      AAdd( aLine, "   QPointer< "+ cObjPfx + ::cQtObject +" > ph;" )
   ELSE
      IF ::isList
          AAdd( aLine, "   " + cObjPfx + ::cQtObject + "< void * > * ph;"                    )
      ELSE
          AAdd( aLine, "   " + cObjPfx + ::cQtObject + " * ph;"                    )
      ENDIF
   ENDIF
   AAdd( aLine, "   bool bNew;"                     )
   AAdd( aLine, "   PHBQT_GC_FUNC func;"            )
   AAdd( aLine, "   HB_U32 type;"                   )
   AAdd( aLine, "   PHBQT_GC_FUNC mark;"            )
   AAdd( aLine, "} HBQT_GC_T_" + ::cQtObject + ";"  )
   AAdd( aLine, " "                                 )
   AAdd( aLine, " "                                 )
   IF n > 0
      AEval( ::code_, {| e | AAdd( aLine, StrTran( e, chr( 13 ) ) ) }, n )
   ENDIF
   AAdd( aLine, " "                                 )
   AAdd( aLine, " "                                 )

   AAdd( aLine, "HBQT_GC_FUNC( hbqt_gcRelease_" + ::cQtObject + " )"  )
   AAdd( aLine, "{"                                     )
   IF ::isDestructor .AND. ::isConstructor
      IF ::isObject
         AAdd( aLine, "   HBQT_GC_T_" + ::cQtObject + " * p = ( HBQT_GC_T_" + ::cQtObject + " * ) Cargo; " )
         AAdd( aLine, "   " )
         AAdd( aLine, "   if( p )" )
         AAdd( aLine, "   {" )
         AAdd( aLine, "      if( p->bNew )" )
         AAdd( aLine, "      {" )
         AAdd( aLine, "         if( p->ph )" )
         AAdd( aLine, "         {" )
#ifdef _GEN_TRACE_
         AAdd( aLine, '            HB_TRACE( ' + ::cTrMode + ', ( "ph=%p %p YES_rel_' + ::cQtObject + '   /.\\   ", ( void * ) p, ( void * ) p->ph ) );' )
#endif
         AAdd( aLine, "            delete ( " + cObjPfx + ::cQtObject + " * )( p->ph ); " )
#ifdef _GEN_TRACE_
         AAdd( aLine, '            HB_TRACE( ' + ::cTrMode + ', ( "ph=%p %p YES_rel_' + ::cQtObject + '   \\./   ", ( void * ) p, ( void * ) p->ph ) );' )
#endif
         AAdd( aLine, "         }" )
#ifdef _GEN_TRACE_
         AAdd( aLine, "         else" )
         AAdd( aLine, "         {" )
         AAdd( aLine, '            HB_TRACE( ' + ::cTrMode + ', ( "ph=%p DEL_rel_' + ::cQtObject + '    :     already deleted!", ( void * ) p->ph ) );' )
         AAdd( aLine, "         }" )
#endif
         AAdd( aLine, "      }" )
#ifdef _GEN_TRACE_
         AAdd( aLine, "      else" )
         AAdd( aLine, "      {" )
         AAdd( aLine, '         HB_TRACE( ' + ::cTrMode + ', ( "ph=%p PTR_rel_' + ::cQtObject + '    :    not a _new_ object", ( void * ) p->ph ) );' )
         AAdd( aLine, "      }" )
#endif
         AAdd( aLine, "      p->ph = NULL;" )
         AAdd( aLine, "   }" )
#ifdef _GEN_TRACE_
         AAdd( aLine, "   else" )
         AAdd( aLine, "   {" )
         AAdd( aLine, '      HB_TRACE( ' + ::cTrMode + ', ( "DEL_rel_' + ::cQtObject + '    :     not valid GC object" ) );' )
         AAdd( aLine, "   }" )
#endif
      ELSE
         AAdd( aLine, "   HBQT_GC_T_" + ::cQtObject + " * p = ( HBQT_GC_T_" + ::cQtObject + " * ) Cargo; " )
         AAdd( aLine, "   " )
         AAdd( aLine, "   if( p )" )
         AAdd( aLine, "   {" )
         AAdd( aLine, "      if( p->bNew )" )
         AAdd( aLine, "      {" )
         AAdd( aLine, "         if( p->ph )" )
         AAdd( aLine, "         {" )
#ifdef _GEN_TRACE_
         AAdd( aLine, '            HB_TRACE( ' + ::cTrMode + ', ( "ph=%p    _rel_' + ::cQtObject + '   /.\\", ( void * ) p->ph ) );' )
#endif
         IF ::isList
         AAdd( aLine, "            int i; " )
         AAdd( aLine, "            for( i = 0; i < p->ph->size(); i++ )" )
         AAdd( aLine, "            {" )
         AAdd( aLine, "               hb_itemRelease( p->ph->at( i ) );" )
         AAdd( aLine, "            }" )
         ENDIF
         AAdd( aLine, "            delete ( ( " + cObjPfx + ::cQtObject + iif( ::isList, "< void * >", "" ) + " * ) p->ph ); " )
#ifdef _GEN_TRACE_
         AAdd( aLine, '            HB_TRACE( ' + ::cTrMode + ', ( "ph=%p YES_rel_' + ::cQtObject + '   \\./", ( void * ) p->ph ) );' )
#endif
         AAdd( aLine, "         }" )
#ifdef _GEN_TRACE_
         AAdd( aLine, "         else" )
         AAdd( aLine, "         {" )
         AAdd( aLine, '            HB_TRACE( ' + ::cTrMode + ', ( "ph=%p DEL_rel_' + ::cQtObject + '    :     object already deleted!", ( void * ) p->ph ) );' )
         AAdd( aLine, "         }" )
#endif
         AAdd( aLine, "      }" )
#ifdef _GEN_TRACE_
         AAdd( aLine, "      else" )
         AAdd( aLine, "      {" )
         AAdd( aLine, '         HB_TRACE( ' + ::cTrMode + ', ( "ph=%p DEL_rel_' + ::cQtObject + '    :     not a _new_ object!", ( void * ) p->ph ) );' )
         AAdd( aLine, "      }" )
#endif
         AAdd( aLine, "      p->ph = NULL;" )
         AAdd( aLine, "   }" )
#ifdef _GEN_TRACE_
         AAdd( aLine, "   else" )
         AAdd( aLine, "   {" )
         AAdd( aLine, '      HB_TRACE( ' + ::cTrMode + ', ( "ph=%p PTR_rel_' + ::cQtObject + '    :    not a valid GC object!", ( void * ) p ) );' )
         AAdd( aLine, "   }" )
#endif
      ENDIF
   ELSE
      AAdd( aLine, "   /* CASE else */" )
      AAdd( aLine, "   HBQT_GC_T * p = ( HBQT_GC_T * ) Cargo;" )
      AAdd( aLine, "   " )
      AAdd( aLine, "   if( p && p->bNew )" )
      AAdd( aLine, "      p->ph = NULL;" )
   ENDIF
   AAdd( aLine, "}" )
   AAdd( aLine, "" )

   AAdd( aLine, "void * hbqt_gcAllocate_" + ::cQtObject + "( void * pObj, bool bNew )" )
   AAdd( aLine, "{                                      " )
   IF ::isObject
      AAdd( aLine, "   HBQT_GC_T_" + ::cQtObject + " * p = ( HBQT_GC_T_" + ::cQtObject + " * ) hb_gcAllocate( sizeof( HBQT_GC_T_" + ::cQtObject + " ), hbqt_gcFuncs() );" )
   ELSE
      AAdd( aLine, "   HBQT_GC_T_" + ::cQtObject + " * p = ( HBQT_GC_T_" + ::cQtObject + " * ) hb_gcAllocate( sizeof( HBQT_GC_T_" + ::cQtObject + " ), hbqt_gcFuncs() );" )
   ENDIF
   AAdd( aLine, "" )
   IF ::isObject
      AAdd( aLine, "   new( & p->ph ) QPointer< "+ cObjPfx + ::cQtObject +" >( ( " + cObjPfx + ::cQtObject + " * ) pObj );" )
   ELSE
      AAdd( aLine, "   p->ph = ( " + cObjPfx + ::cQtObject + iif( ::isList, "< void * >", "" ) + " * ) pObj;" )
   ENDIF
   AAdd( aLine, "   p->bNew = bNew;" )
   AAdd( aLine, "   p->func = hbqt_gcRelease_" + ::cQtObject + ";" )
   AAdd( aLine, "   p->type = HBQT_TYPE_" + ::cQtObject + ";" )
   if n > 0
      AAdd( aLine, "   p->mark = hbqt_gcMark_" + ::cQtObject + ";" )
   else
      AAdd( aLine, "   p->mark = NULL;" )
   endif
   AAdd( aLine, "" )
#ifdef _GEN_TRACE_
   AAdd( aLine, "   if( bNew )" )
   AAdd( aLine, "   {" )
   AAdd( aLine, '      HB_TRACE( ' + ::cTrMode + ', ( "ph=%p    _new_' + ::cQtObject + iif( ::isObject, '  under p->pq', '' ) + '", ( void * ) pObj ) );' )
   AAdd( aLine, "   }" )
   AAdd( aLine, "   else" )
   AAdd( aLine, "   {" )
   AAdd( aLine, '      HB_TRACE( ' + ::cTrMode + ', ( "ph=%p NOT_new_' + ::cQtObject + '", ( void * ) pObj ) );' )
   AAdd( aLine, "   }" )
#endif
   AAdd( aLine, "   return p;" )
   AAdd( aLine, "}" )
   IF ::cQtVer > "0x040500"
      AAdd( aLine, "#endif" )
   ENDIF
   AAdd( aLine, "" )
   
   AAdd( aLine, 'static PHB_ITEM s_oClass = NULL;' )
   AAdd( aLine, "" )
   
   AAdd( aLine, 'void hbqt_register_' + lower( uQtObject ) + '()' )
   AAdd( aLine, "{" )
   AAdd( aLine, '   HB_TRACE( HB_TR_DEBUG, ( "hbqt_register_' + lower( uQtObject ) + '()" ) );' )
   AAdd( aLine, "   HB_HBQT_LOCK" )
   AAdd( aLine, "   if( s_oClass == NULL )" )
   AAdd( aLine, "   {" )
   AAdd( aLine, "      s_oClass = hb_itemNew( NULL );" )
   AAdd( aLine, "      hbqt_addDeleteList( s_oClass );" )
   FOR EACH k IN hb_aTokens( s, "," )
      k := lower( AllTrim( k ) )
      IF k == "hbqtobjecthandler"
         AAdd( aLine, "      HB_FUNC_EXEC( " + Upper( k ) + " );" )
      ELSE    
         AAdd( aLine, "      hbqt_register_" + substr( k, 4 ) + "();" )
      ENDIF    
   NEXT
   AAdd( aLine, '      PHB_ITEM oClass = hbqt_defineClassBegin( "' + uQtObject + '", s_oClass, "' + s + '" );' )
   AAdd( aLine, "      if( oClass )" )
   AAdd( aLine, "      {" )
   AAdd( aLine, "         s_registerMethods( hb_objGetClass( hb_stackReturnItem() ) );" )
   AAdd( aLine, "         hbqt_defineClassEnd( s_oClass, oClass );" )
   AAdd( aLine, "      }" )
   AAdd( aLine, "   }" )
   AAdd( aLine, "   HB_HBQT_UNLOCK" )
   AAdd( aLine, "}" )
   AAdd( aLine, "" )
      
   AAdd( aLine, "HB_FUNC( HB_" + uQtObject + " )" )
   AAdd( aLine, "{" ) 
   AAdd( aLine, '   HB_TRACE( HB_TR_DEBUG, ( "HB_' +  uQtObject + '" ) );' ) 
   AAdd( aLine, "   if( s_oClass == NULL )" ) 
   AAdd( aLine, "   {" )
   AAdd( aLine, "       hbqt_register_" + lower( uQtObject ) + "();" )
   AAdd( aLine, "   }" ) 
   AAdd( aLine, '   hb_objSendMsg( s_oClass, "INSTANCE", 0 );' ) 
   AAdd( aLine, "}" ) 
   AAdd( aLine, "" ) 

   /* Build PRG level constructor */
   AAdd( aLine, ::newW_[ 1 ] )           // Func definition
   AAdd( aLine, ::newW_[ 2 ] )           // {
   AEval( ::getConstructorW(), {| e | AAdd( aLine, e ) } )

   /* Build the constructor */
   AAdd( aLine, ::new_[ 1 ] )           // Func definition
   AAdd( aLine, ::new_[ 2 ] )           // {
   AEval( ::getConstructor( 0 ), {| e | AAdd( aLine, e ) } )

   /* Insert Functions */
   AEval( ::txt_, {| e | AAdd( aLine, StrTran( e, chr( 13 ) ) ) } )

   AAdd( aLine, "" )
   AAdd( aLine, "static void s_registerMethods( HB_USHORT uiClass )" )
   AAdd( aLine, "{" )
   AAdd( aLine, '   hb_clsAdd( uiClass, ' + PadR( '"new"', 35) +', HB_FUNCNAME( ' + PadR( Upper( "NEW" ), 35) + ' ) );' )
   FOR EACH oMtd IN ::aMethods
      IF ! Empty( oMtd:cHBFunc )
         AAdd( aLine, '   hb_clsAdd( uiClass, ' + PadR( '"' + oMtd:cHBFunc +'"', 35 ) +', HB_FUNCNAME( ' + PadR( Upper( oMtd:cHBFunc ), 35) + ' ) );' )
      ENDIF
   NEXT
   AAdd( aLine, "}" )
   AAdd( aLine, "" )
   AAdd( aLine, "HB_INIT_SYMBOLS_BEGIN( __HBQT_CLS_" + uQtObject  + "__ )" )
   AAdd( aLine, '   { "' + uQtObject + '", { HB_FS_PUBLIC | HB_FS_LOCAL }, { HB_FUNCNAME( ' + uQtObject + ' ) }, NULL },' )
   AAdd( aLine, '   { "HB_' + uQtObject + '", { HB_FS_PUBLIC | HB_FS_LOCAL }, { HB_FUNCNAME( HB_' + uQtObject + ' ) }, NULL }' )
   AAdd( aLine, "HB_INIT_SYMBOLS_END( __HBQT_CLS_" + uQtObject + "__ )" )
   AAdd( aLine, "" )

   /* Footer */
   hbqtgen_BuildFooter( @aLine )

   /* Build Document File */
   ::buildDOC()

   /* Build Protected Events Implimentation */
   ::buildExtendedHeader()

   /* Distribute in specific lib subfolder */
   hbqtgen_CreateTarget( ::cCPPFileName, aLine )

   RETURN Self

/*----------------------------------------------------------------------*/

METHOD HbQtSource:exploreExtensions()
   LOCAL n

   IF ( n := AScan( ::cls_, {|e_| Upper( e_[ 1 ] ) $ "PAINTEVENT" } ) ) > 0
      IF ! Empty( ::cls_[ n,2 ] )
         ::lPaintEvent := .t.
      ENDIF
   ENDIF

   // check other events

   // Test IF extended code is TO be built
   IF ::lPaintEvent // .OR. ::lOtherEvent
      ::lBuildExtended := .t.
   ENDIF

   RETURN Self

/*----------------------------------------------------------------------*/

METHOD HbQtSource:buildExtendedHeader()
   LOCAL cPath, txt_, cObj

   IF ! ::lBuildExtended
      RETURN Self
   ENDIF

   cObj := ::cQtObject
   txt_:= {}

   aadd( txt_, '' )
   aadd( txt_, '#include "hbapiitm.h" ' )
   aadd( txt_, '' )
   aadd( txt_, 'HB_EXTERN_BEGIN' )
   IF ::lPaintEvent
   AAdd( txt_, 'extern HB_EXPORT void * hbqt_gcAllocate_QPaintEvent( void * pObj, bool bNew );' )
   AAdd( txt_, 'extern HB_EXPORT void * hbqt_gcAllocate_QPainter( void * pObj, bool bNew );' )
   ENDIF
   aadd( txt_, 'HB_EXTERN_END' )
   aadd( txt_, '' )
   aadd( txt_, '#include <QtGui/' + cObj + '>' )
   IF ::lPaintEvent
   aadd( txt_, '#include <QtGui/QStyleOption>' )
   aadd( txt_, '#include <QtGui/QPainter>' )
   aadd( txt_, '#include <QtGui/QPaintEvent>' )
   ENDIF
   aadd( txt_, '' )
   aadd( txt_, 'class Q' + cObj + ' : public ' + cObj )
   aadd( txt_, '{' )
   aadd( txt_, '   Q_OBJECT' )
   aadd( txt_, '' )
   aadd( txt_, 'public:' )

   SWITCH cObj
   CASE "QWidget"
   aadd( txt_, '   Q' + cObj + '( QWidget * parent = 0, Qt::WindowFlags f = 0 );' )
   EXIT
   OTHERWISE
   aadd( txt_, '   Q' + cObj + '( QWidget * parent = 0 );' )
   EXIT
   ENDSWITCH

   aadd( txt_, '   virtual ~Q' + cObj + '();' )
   aadd( txt_, '' )
   aadd( txt_, '   void hbSetEventBlock( int event, PHB_ITEM pBlock );' )
   aadd( txt_, '' )
   IF ::lPaintEvent
   aadd( txt_, '   PHB_ITEM pPaintBlock;' )
   aadd( txt_, '   void paintEvent ( QPaintEvent * event );' )
   ENDIF
   aadd( txt_, '};' )
   aadd( txt_, '' )

   aeval( txt_, {|e,i| txt_[ i ] := trim( e ) } )

   hb_fNameSplit( ::cCPPFileName, @cPath )

   hbqtgen_CreateTarget( cPath + "q" + lower( ::cQtObject ) + ".h", txt_ )

   RETURN Self

/*----------------------------------------------------------------------*/

METHOD HbQtSource:buildExtendedSource( t_ )
   LOCAL txt_, cObj

   IF ! ::lBuildExtended
      RETURN Self
   ENDIF

   cObj := ::cQtObject
   txt_ := {}

   IF ::cQtVer > "0x040500"
      AAdd( txt_, "#if QT_VERSION >= " + ::cQtVer )
   ENDIF

   AAdd( txt_, '' )
   AAdd( txt_, '#include "q' + Lower( cObj ) + '.h"' )
   AAdd( txt_, '' )

   SWITCH cObj
   CASE "QWidget"
   AAdd( txt_, 'Q' + cObj + '::Q' + cObj + '( QWidget * parent, Qt::WindowFlags f ) : ' + cObj + '( parent, f )' )
   EXIT
   OTHERWISE
   AAdd( txt_, 'Q' + cObj + '::Q' + cObj + '( QWidget * parent ) : ' + cObj + '( parent )' )
   EXIT
   ENDSWITCH

   AAdd( txt_, '{' )
   IF ::lPaintEvent
   AAdd( txt_, '   pPaintBlock = NULL;' )
   ENDIF
   AAdd( txt_, '}' )
   AAdd( txt_, 'Q' + cObj + '::~Q' + cObj + '()' )
   AAdd( txt_, '{' )
   IF ::lPaintEvent
   AAdd( txt_, '   if( pPaintBlock )' )
   AAdd( txt_, '   {' )
   AAdd( txt_, '      hb_itemRelease( pPaintBlock );' )
   AAdd( txt_, '      pPaintBlock = NULL;' )
   AAdd( txt_, '   }' )
   ENDIF
   AAdd( txt_, '}' )
   AAdd( txt_, 'void Q' + cObj + '::hbSetEventBlock( int event, PHB_ITEM pBlock )' )
   AAdd( txt_, '{' )
   AAdd( txt_, '   switch( event )' )
   AAdd( txt_, '   {' )
   IF ::lPaintEvent
   AAdd( txt_, '      case QEvent::Paint:' )
   AAdd( txt_, '      {' )
   AAdd( txt_, '         if( pPaintBlock )' )
   AAdd( txt_, '         {' )
   AAdd( txt_, '            hb_itemRelease( pPaintBlock );' )
   AAdd( txt_, '         }' )
   AAdd( txt_, '         pPaintBlock = hb_itemNew( pBlock );' )
   AAdd( txt_, '         hb_gcUnlock( pPaintBlock );' )
   AAdd( txt_, '         break;' )
   AAdd( txt_, '      }' )
   ENDIF
   AAdd( txt_, '   }' )
   AAdd( txt_, '}' )
   IF ::lPaintEvent
   AAdd( txt_, 'void Q' + cObj + '::paintEvent( QPaintEvent * event )' )
   AAdd( txt_, '{' )
   AAdd( txt_, '   bool bEventHandelled = false;' )
   AAdd( txt_, '   if( pPaintBlock )' )
   AAdd( txt_, '   {' )
   AAdd( txt_, '      QPainter painter( this );' )
   AAdd( txt_, '      PHB_ITEM p0 = hb_itemNew( hbqt_create_objectGC( hbqt_gcAllocate_QPaintEvent( event, false ), "hb_QPaintEvent" ) );' )
   AAdd( txt_, '      PHB_ITEM p1 = hb_itemNew( hbqt_create_objectGC( hbqt_gcAllocate_QPainter( &painter, false ), "hb_QPainter" ) );' )
   AAdd( txt_, '      bEventHandelled = hb_itemGetL( hb_vmEvalBlockV( pPaintBlock, 2, p0, p1 ) );' )
   AAdd( txt_, '      hb_itemRelease( p0 );' )
   AAdd( txt_, '      hb_itemRelease( p1 );' )
   AAdd( txt_, '   }' )
   AAdd( txt_, '   if( ! bEventHandelled )' )
   AAdd( txt_, '   {' )
   AAdd( txt_, '      QStyleOption opt;' )
   AAdd( txt_, '      opt.init( this );' )
   AAdd( txt_, '      QPainter p( this );' )
   AAdd( txt_, '      style()->drawPrimitive( QStyle::PE_Widget, &opt, &p, this );' )
   AAdd( txt_, '      ' + cObj + '::paintEvent( event );' )
   AAdd( txt_, '   }' )
   AAdd( txt_, '}' )
   ENDIF
   AAdd( txt_, '' )

   AEval( txt_, {|e| aadd( t_, trim( e ) ) } )

   IF ::cQtVer > "0x040500"
      AAdd( txt_, "#endif" )
   ENDIF

   RETURN Self

/*----------------------------------------------------------------------*/

METHOD HbQtSource:getConstructor()
   LOCAL i, s, aLine := {}
   LOCAL cObjPfx := iif( ::lBuildExtended, "Q", "" )

   IF ::cQtVer > "0x040500"
      AAdd( aLine, "#if QT_VERSION >= " + ::cQtVer )
   ENDIF
   IF ::isConstructor
      IF ::isList
         AAdd( aLine, "   " + cObjPfx + ::cQtObject + "< void * > * pObj = NULL;" )
      ELSE
         AAdd( aLine, "   " + cObjPfx + ::cQtObject + " * pObj = NULL;" )
      ENDIF
      AAdd( aLine, " " )
      FOR i := 3 TO Len( ::new_ ) - 1
         IF !( Left( LTrim( ::new_[ i ] ), 2 ) == "//" )
            IF "__HB_RETPTRGC__(" $ ::new_[ i ]
               s := ::new_[ i ]
               s := RTrim( StrTran( s, "__HB_RETPTRGC__(", "pObj =" ) )
               IF ");" $ s
                  s := RTrim( StrTran( s, ");" ) ) + ";"
               ENDIF
               s := StrTran( s, "( " + ::cQtObject + "* )" )
               s := StrTran( s, "new ", "new " + cObjPfx )
               AAdd( aLine, s )
            ELSE
               AAdd( aLine, ::new_[ i ] )
            ENDIF
         ENDIF
      NEXT
      AAdd( aLine, " " )
      AAdd( aLine, "   hbqt_itemPushReturn( hbqt_gcAllocate_" + ::cQtObject + "( ( void * ) pObj, " + iif( ::isDetached, "false", "true" ) + " ), hb_stackSelfItem() );" )
   ELSE
      FOR i := 3 TO Len( ::new_ ) - 1
         AAdd( aLine, ::new_[ i ] )
      NEXT
   ENDIF
   IF ::cQtVer > "0x040500"
      AAdd( aLine, "#endif" )
   ENDIF
   AAdd( aLine, ::new_[ Len( ::new_ ) ] ) // }
   AAdd( aLine, "" )

   RETURN aLine

/*----------------------------------------------------------------------*/

METHOD HbQtSource:getConstructorW()
   LOCAL aLine := ::getConstructor()

   AEval( aLine, {| e, i | aLine[ i ] := StrTran( e, "hbqt_itemPushReturn", "hbqt_create_objectGC" ) } )
   AEval( aLine, {| e, i | aLine[ i ] := StrTran( e, "hb_stackSelfItem()" , '"HB_' + Upper( ::cQtObject ) + '"' ) } )

   RETURN aLine

/*----------------------------------------------------------------------*/

METHOD HbQtSource:normalizeCmd( oMtd, v )
   LOCAL FP

   oMtd:cCmd := StrTran( oMtd:cCmd, "(  )", "()" )

   IF ! oMtd:isConstructor
      FP := StrTran( oMtd:cCmd, "hbqt_par_" + ::cQtObject + "( 1 )", v, 1, 1 )
   ELSE
      FP := oMtd:cCmd
   ENDIF

   /* Manage Re-Attached */
   IF oMtd:nAttach > 0
      FP := StrTran( FP, ", false", ", true" )
   ENDIF

   RETURN FP

/*----------------------------------------------------------------------*/

METHOD HbQtSource:getReturnAsList( oMtd, FP, cPrefix )
   LOCAL cRetCast, n, n1, cCast, cParas, nStrCnt, lFar
   LOCAL aLines := {}

   IF oMtd:isRetList
      cRetCast := oMtd:oRet:cCast
      lFar := "*" $ cRetCast
      IF ( n := at( "<", cRetCast ) ) > 0
         IF ( n1 := at( ">", cRetCast ) ) > 0
            cCast := AllTrim( SubStr( cRetCast, n + 1, n1 - n - 1 ) )
            cCast := StrTran( cCast, "*" )
            cCast := StrTran( cCast, " " )
         ENDIF
      ENDIF
      IF ! Empty( cCast )
         cParas := oMtd:cParas
         nStrCnt := 0
         DO WHILE "%%%" $ cParas
            ++nStrCnt
            cParas := StrTran( cParas, "%%%", StrZero( nStrCnt, 2, 0 ), 1, 1 )
         ENDDO

         AAdd( aLines, cPrefix + 'QList<PHB_ITEM> * qList = new QList< PHB_ITEM >;' )
         AAdd( aLines, cPrefix + cRetCast + ' qL = p->' + oMtd:cFun + cParas + ';' )
         AAdd( aLines, cPrefix + "int i;" )
         AAdd( aLines, cPrefix + "for( i = 0; i < qL.size(); i++ )" )
         AAdd( aLines, cPrefix + "{" )
         IF cCast == "QString"
            AAdd( aLines, cPrefix + '   const char * str = qL.at( i ).data();' )
            AAdd( aLines, cPrefix + '   PHB_ITEM pItem = hb_itemNew( NULL );' )
            AAdd( aLines, cPrefix + '   hb_itemPutCL( pItem, str, strlen( str ) );' )
            AAdd( aLines, cPrefix + '   qList->append( pItem );' )
         ELSEIF cCast == "int"
            AAdd( aLines, cPrefix + '   // TOFIX: how TO release pItem ? ' )
            AAdd( aLines, cPrefix + '   PHB_ITEM pItem = hb_itemNew( NULL );' )
            AAdd( aLines, cPrefix + '   hb_itemPutNI( pItem, qL.at( i ) );' )
            AAdd( aLines, cPrefix + '   qList->append( pItem );' )
         ELSEIF cCast == "qreal"
            AAdd( aLines, cPrefix + '   // TOFIX: how TO release pItem ? ' )
            AAdd( aLines, cPrefix + '   PHB_ITEM pItem = hb_itemNew( NULL );' )
            AAdd( aLines, cPrefix + '   hb_itemPutND( pItem, qL.at( i ) );' )
            AAdd( aLines, cPrefix + '   qList->append( pItem );' )
         ELSE
            IF lFar
               AAdd( aLines, cPrefix + '   qList->append( hb_itemNew( hbqt_create_objectGC( hbqt_gcAllocate_' + cCast + '( ( void * ) qL.at( i ), false ) , "HB_' + Upper( cCast ) + '" ) ) );' )
            ELSE
               AAdd( aLines, cPrefix + '   qList->append( hb_itemNew( hbqt_create_objectGC( hbqt_gcAllocate_' + cCast + '( new ' + cCast + '( qL.at( i ) ), true ) , "HB_' + Upper( cCast ) + '" ) ) );' )
            ENDIF
         ENDIF
         AAdd( aLines, cPrefix + '}' )
         AAdd( aLines, cPrefix + 'hbqt_create_objectGC( hbqt_gcAllocate_QList( qList, true ), "HB_QLIST" );' )
      ENDIF
   ELSE
      AAdd( aLines, cPrefix + FP + ";" )
   ENDIF

   RETURN aLines

/*----------------------------------------------------------------------*/

METHOD HbQtSource:getReturnMethod( oMtd, lAddRet )
   LOCAL txt_, nStrCnt, n, FP, v

   txt_:= {}

   v := "p"  /* NEVER change this */
   FP := ::normalizeCmd( oMtd, v )

   IF ! Empty( oMtd:aPre )
      FOR n := 1 TO Len( oMtd:aPre )
         AAdd( txt_, oMtd:aPre[ n, 1 ] )
      NEXT
      AAdd( txt_, "" )
   ENDIF

   /* Manage detached Argument */
   IF oMtd:nDetach > 0
      AAdd( txt_, "hbqt_par_detach_ptrGC( " + hb_ntos( oMtd:nDetach ) + " );" )
   ENDIF

   nStrCnt := 0
   DO WHILE "%%%" $ FP
      ++nStrCnt
      FP := StrTran( FP, "%%%", StrZero( nStrCnt, 2, 0 ), 1, 1 )
      AAdd( txt_, "void * pText" + StrZero( nStrCnt, 2, 0 ) + " = NULL;" )
   ENDDO

   AEval( ::getReturnAsList( oMtd, FP, "" ), {| e | AAdd( txt_, e ) } )

   FOR n := nStrCnt TO 1 STEP -1
      AAdd( txt_, "hb_strfree( pText" + StrZero( n, 2, 0 ) + " );" )
   NEXT

   /* Return values back to PRG */
   IF ! Empty( oMtd:aPre )
      AAdd( txt_, "" )
      FOR n := 1 TO Len( oMtd:aPre )
         AAdd( txt_, oMtd:aPre[ n, 4 ] + "( " + oMtd:aPre[ n, 3 ] + ", " + hb_ntos( oMtd:aPre[ n, 2 ] ) + " );" )
      NEXT
   ENDIF

   IF lAddRet
      AAdd( txt_, "return;" )
   ENDIF

   RETURN txt_

/*----------------------------------------------------------------------*/

METHOD HbQtSource:getMethodBody( oMtd, cMtdName, aMethods )
   LOCAL cTmp, n, v, ooMtd, i, nArgs, nArgGrps
   LOCAL txt_:= {}, a_:= {}, b_:= {}, c_:= {}, d_:= {}
   LOCAL cCrc, nMtds, lInIf, lFirst, nTySame

   HB_SYMBOL_UNUSED( cMtdName )

   /* check for methods already been worked on */
   IF AScan( ::func_, { |e_ | e_[ 1 ] == oMtd:cFun } ) > 0
      RETURN {}
   ENDIF
   AAdd( ::func_, { oMtd:cFun, 0, "" } )

   oMtd:cHBFunc := oMtd:cFun
   oMtd:cCmd    := StrTran( oMtd:cCmd, "(  )", "()" )

   FOR EACH ooMtd IN aMethods
      IF ooMtd:cFun == oMtd:cFun
         AAdd( a_, ooMtd )
      ENDIF
   NEXT

   /* Display method prototypes on top of the method body */
   FOR EACH ooMtd IN a_
      AAdd( txt_, "/* " + StrTran( ooMtd:cProto, chr( 13 ) ) + " */" )
   NEXT

   v := "p"  /* NEVER change this */

   AAdd( txt_, "HB_FUNC_STATIC( " + Upper( oMtd:cHBFunc ) + " )" )
   AAdd( txt_, "{" )
   IF ! empty( oMtd:cVersion )
      AAdd( txt_, "   #if QT_VERSION >= " + oMtd:cVersion )
   ELSEIF ::cQtVer > "0x040500"
      AAdd( txt_, "   #if QT_VERSION >= " + ::cQtVer )
   ENDIF
#ifdef _GEN_TRACE_
   AAdd( txt_, '   HB_TRACE( ' + ::cTrMode + ', ( "' + ::cQtObject + ":" + oMtd:cHBFunc + '" ) );' )
#endif

   /* If method is manually written in .qth - no more processing */
   IF ! Empty( oMtd:fBody_ )
      AEval( oMtd:fBody_, {| e | AAdd( txt_, e ) } )
      AAdd( txt_, "}" )
      AAdd( txt_, "" )
      RETURN txt_
   ENDIF

   /* Sort per number of arguments */
   asort( a_, , , {| e, f | StrZero( e:nArgs, 2 ) + iif( e:nArgs == 0, "", e:hArgs[ 1 ]:cTypeHB ) > StrZero( f:nArgs, 2 ) + iif( f:nArgs == 0, "", f:hArgs[ 1 ]:cTypeHB )  } )

   /* know the maximum groups by number of parameters - first CASE */
   AEval( a_, {| o | iif( AScan( b_, o:nArgs ) == 0, AAdd( b_, o:nArgs ), NIL ) } )

   /* also take into account optional arguments if any */
   FOR EACH ooMtd IN a_
      IF ooMtd:nArgsReal < ooMtd:nArgs
         FOR i := ooMtd:nArgs - 1 TO ooMtd:nArgsReal STEP -1
            IF AScan( b_, i ) == 0
               AAdd( b_, i )
            ENDIF
         NEXT
      ENDIF
   NEXT

   /* Build the structure number of parameters wise */
   FOR EACH nArgs IN b_
      AAdd( c_, { nArgs, {}, {}, {} } )
      n := Len( c_ )
      FOR EACH ooMtd IN a_
         IF ooMtd:nArgs == nArgs
            AAdd( c_[ n, 2 ], ooMtd )
         ENDIF
      NEXT
      /* Again append methods with optional arguments */
      FOR EACH ooMtd IN a_
         IF ooMtd:nArgsReal < ooMtd:nArgs
            FOR i := ooMtd:nArgs - 1 TO ooMtd:nArgsReal STEP -1
               IF i == nArgs
                  AAdd( c_[ n, 2 ], ooMtd )
               ENDIF
            NEXT
         ENDIF
      NEXT
   NEXT

   /* stack groups based on parameters descending */
   asort( c_, , , {| e, f | e[ 1 ] > f[ 1 ] } )

   /* again sort no of arguments based methods by type of arguments */
   FOR i := 10 TO 0 STEP -1  /* consider maximum 10 arguments */
      IF ( n := AScan( c_, {| e_ | e_[ 1 ] == i } ) ) > 0
         d_:= c_[ n, 2 ]                      // d_ == a_
         asort( d_, , , {| e, f | __TY( e, c_[ n, 1 ] ) < __TY( f, c_[ n, 1 ] ) } )
      ENDIF
   NEXT


   cTmp := iif( ::lBuildExtended, "Q", "" ) + ::cQtObject + iif( ::isList, "< void * >", "" )
   AAdd( txt_, "   " + cTmp + " * " + v + " = ( " + cTmp + " * ) hbqt_par_ptr( 0 );" )

   AAdd( txt_, "   if( " + v + " )" )
   AAdd( txt_, "   {" )

   IF Len( a_ ) == 1 .and. oMtd:nArgs == oMtd:nArgsReal    /* Only one method - no overloads */
      FOR EACH b_ IN c_
         nArgs    := b_[ 1 ]
         a_       := b_[ 2 ]
         FOR EACH oMtd IN a_
            IF oMtd:nArgs > 0
               AAdd( txt_, "      " + iif( oMtd:__enumIndex() == 1, "if", "else if" ) + "( " + __TY_TYPEScpp( oMtd, nArgs, .f. ) + " )" )
               AAdd( txt_, "      {" )
            ENDIF
            //
            AEval( ::getReturnMethod( oMtd, ( oMtd:nArgs > 0 ) ), {| e | AAdd( txt_, Space( iif( oMtd:nArgs > 0, 9, 6 ) ) + e ) } )
            //
            IF oMtd:nArgs > 0
               AAdd( txt_, "      }" )
               AAdd( txt_, "      hb_errRT_BASE( EG_ARG, 9999, NULL, HB_ERR_FUNCNAME, HB_ERR_ARGS_BASEPARAMS );" )
            ENDIF
         NEXT
      NEXT

   ELSE

      nArgs := 0
      AAdd( txt_, "      switch( hb_pcount() )" )
      AAdd( txt_, "      {" )

      FOR EACH b_ IN c_
         nArgs    := b_[ 1 ]
         a_       := b_[ 2 ]
         nArgGrps := Len( c_ )
         cCrc     := "xxx"
         nMtds    := 0
         lInIf    := .F.
         nTySame  := 0
         lFirst   := nArgs > 0

         AAdd( txt_, "         case " + hb_ntos( nArgs ) + ":" )      /* number of parameters */
         AAdd( txt_, "         {" )

         FOR EACH oMtd IN a_
            IF nArgs > 0
               IF !( cCrc == __TY( oMtd, nArgs ) )
                  cCrc    := __TY( oMtd, nArgs )
                  nMtds   := 0
                  nTySame := 0
                  AEval( a_, {| o | iif( __TY( o,nArgs ) == cCrc, nTySame++, NIL ) } )
                  lInIf   := oMtd:nArgQCast > 0 .AND. oMtd:nArgQCast <= nArgs .AND. nTySame > 1
                  AAdd( txt_, "            " + iif( lFirst, "if( ", "else if( " ) + __TY_TYPEScpp( oMtd, nArgs, nTySame > 1 ) + " )" )
                  AAdd( txt_, "            {" )
               ENDIF
            ENDIF
            IF lFirst
               lFirst := .F.
            ENDIF

            nMtds++

            IF lInIf
               AAdd( txt_, "               " + iif( nMtds == 1, "if( ", "else if( " ) + __TY_Method( oMtd, nArgs ) + " )" )
               AAdd( txt_, "               {" )
            ENDIF
            //
            AEval( ::getReturnMethod( oMtd, .T. ), {| e | AAdd( txt_, Space( iif( nArgs == 0, 12, 15 ) + iif( lInIf, 3, 0 ) ) + e ) } )
            //
            IF lInIf
               AAdd( txt_, "               }" )
            ENDIF

            IF nArgs > 0 .AND. ! lInIf
               AAdd( txt_, "            }" )
            ELSEIF nArgs > 0 .AND. lInIf .AND. nMtds == nTySame
               AAdd( txt_, "            }" )
            ENDIF
         NEXT
         IF nArgs > 0
            AAdd( txt_, "            break;" )
            AAdd( txt_, "         }" )
         ENDIF
      NEXT
      IF nArgs == 0
         AAdd( txt_, "         }" )  // CASE
      ENDIF
      AAdd( txt_, "      }" )        // SWITCH
      AAdd( txt_, "      hb_errRT_BASE( EG_ARG, 9999, NULL, HB_ERR_FUNCNAME, HB_ERR_ARGS_BASEPARAMS );" )

   ENDIF

   AAdd( txt_, "   }" )           // if( p )
   IF ! empty( oMtd:cVersion ) .OR. ;
      ::cQtVer > "0x040500"
      AAdd( txt_, "   #endif" )
   ENDIF
   AAdd( txt_, "}" )              // HB_FUNC()
   AAdd( txt_, "" )

   HB_SYMBOL_UNUSED( d_ )
   HB_SYMBOL_UNUSED( nArgGrps )

   RETURN txt_

/*----------------------------------------------------------------------*/

METHOD HbQtSource:buildMethodBody( oMtd )
   LOCAL aBdy, cFunc

   oMtd:cCmd := StrTran( oMtd:cCmd, "(  )", "()" )

   aBdy := ::getMethodBody( oMtd, "QT_" + Upper( ::cQtObject ) + "_" + Upper( oMtd:cHBFunc ), ::aMethods )

   AEval( aBdy, {| e | AAdd( ::txt_, e ) } )

   cFunc := iif( ::areMethodsClubbed, hbqtgen_stripLastFrom( oMtd:cHBFunc, "_" ), oMtd:cHBFunc )

   oMtd:cDoc := "Qt_" + ::cQtObject + "_" + cFunc + "( p" + ::cQtObject + ;
                     iif( Empty( oMtd:cDocs ), "", ", " + oMtd:cDocs ) + " ) -> " + oMtd:cPrgRet

   AAdd( ::doc_, oMtd:cDoc )
   AAdd( ::doc_, "" )

   RETURN Self

/*----------------------------------------------------------------------*/

STATIC FUNCTION hbqtgen_prgRetNormalize( cPrgRet )

   cPrgRet := StrTran( cPrgRet, "::", "_" )
   cPrgRet := StrTran( cPrgRet, "<", "_" )
   cPrgRet := StrTran( cPrgRet, " *>" )
   cPrgRet := StrTran( cPrgRet, "*>" )

   RETURN cPrgRet

/*----------------------------------------------------------------------*/

STATIC FUNCTION hbqtgen_paramCheckStrCpp( cType, nArg, cCast, lObj )

   HB_SYMBOL_UNUSED( cCast )

   SWITCH cType
   CASE "PB"
      RETURN "! HB_ISNIL( " + hb_ntos( nArg ) + " )"
   CASE "P"  //TODO
      RETURN "HB_ISPOINTER( " + hb_ntos( nArg ) + " )"
   CASE "O"
      IF lObj
         RETURN "HB_ISOBJECT( " + hb_ntos( nArg ) + " )"
      ELSE    
         RETURN "hbqt_par_isDerivedFrom( " + hb_ntos( nArg ) + ', "' + upper( cCast ) +'" )'
      ENDIF    
   CASE "CO"
      IF lObj
         RETURN "( HB_ISOBJECT( " + hb_ntos( nArg ) + " )" + " || HB_ISCHAR( " + hb_ntos( nArg ) + " ) )"
      ELSE    
         RETURN "( hbqt_par_isDerivedFrom( " + hb_ntos( nArg ) + ', "' + upper( cCast ) + '" )' + " || HB_ISCHAR( " + hb_ntos( nArg ) + " ) )"
      ENDIF    
   CASE "N*"
      RETURN  "HB_ISBYREF( " + hb_ntos( nArg ) + " )"
   CASE "N"
      RETURN  "HB_ISNUM( " + hb_ntos( nArg ) + " )"
   CASE "L*"
      RETURN  "HB_ISBYREF( " + hb_ntos( nArg ) + " )"
   CASE "L"
      RETURN  "HB_ISLOG( " + hb_ntos( nArg ) + " )"
   CASE "C"
      RETURN  "HB_ISCHAR( " + hb_ntos( nArg ) + " )"
   ENDSWITCH

   RETURN ""
/*----------------------------------------------------------------------*/

STATIC FUNCTION __TY_TYPEScpp( oM, nArgs, lObj )
   LOCAL i, s := ""
   FOR i := 1 TO nArgs
      s += hbqtgen_paramCheckStrCpp( oM:hArgs[ i ]:cTypeHB, i, oM:hArgs[ i ]:cCast, lObj ) + " && "
   NEXT
   IF " && " $ s
      s := Left( s, Len( s ) - 4 )
   ENDIF
   RETURN s

/*----------------------------------------------------------------------*/

METHOD HbQtSource:buildDOC()
   LOCAL cText, n, n1, n2, nLen, pWidget, cRet, cLib, i, cInherits

   LOCAL hEntry := { => }

   LOCAL cQT_VER := hb_ntos( hb_HexToNum( SubStr( ::cQtVer, 3, 2 ) ) ) + "." + hb_ntos( hb_HexToNum( SubStr( ::cQtVer, 5, 2 ) ) )

   hb_HKeepOrder( hEntry, .T. )

   n := AScan( ::cls_, {| e_ | Left( Lower( e_[ 1 ] ), 7 ) $ "inherits" .and. ! Empty( e_[ 2 ] ) } )
   cInherits := iif( n > 0, ::cls_[ n, 2 ], "" )

   cLib := ::cQtModule

   hEntry[ "TEMPLATE"     ] := "Class"
   hEntry[ "NAME"         ] := ::cQtObject + "()"
   hEntry[ "CATEGORY"     ] := "Harbour Bindings for Qt"
   hEntry[ "SUBCATEGORY"  ] := "GUI"
   hEntry[ "EXTERNALLINK" ] := "http://doc.trolltech.com/" + cQT_VER + "/" + Lower( ::cQtObject ) + ".html"
   hEntry[ "ONELINER"     ] := "Creates a new " + ::cQtObject + " object."
   hEntry[ "INHERITS"     ] := cInherits
   hEntry[ "SYNTAX"       ] := ::cQtObject + "( ... )" + hb_eol()
   hEntry[ "ARGUMENTS"    ] := ""
   hEntry[ "RETURNS"      ] := "An instance of the object of type " + ::cQtObject
   IF ! Empty( ::doc_ )
      hEntry[ "METHODS"      ] := ""
      nLen    := Len( ::cQtObject )
      n       := at( ::cQtObject, ::doc_[ 1 ] )
      pWidget := "p" + ::cQtObject
      FOR i := 1 TO Len( ::doc_ )
         IF ! Empty( cText := ::doc_[ i ] )
            cText := SubStr( cText, n + nLen + 1 )
            cText := StrTran( cText, pWidget + ", " )
            cText := StrTran( cText, pWidget )
            cText := StrTran( cText, "(  )", "()" )
            n1    := at( "->", cText )
            cRet  := hbqtgen_prgRetNormalize( AllTrim( SubStr( cText, n1 + 2 ) ) )
            cText := SubStr( cText, 1, n1 - 1 )
            n2    := Max( 50, Len( cText ) )
            cText := padR( cText, n2 )
            IF ! Empty( cRet )
               hEntry[ "METHODS" ] += ":" + cText + " -> " + cRet + hb_eol()
            ENDIF
         ENDIF
      NEXT
   ENDIF
   hEntry[ "DESCRIPTION"  ] := ""
   hEntry[ "EXAMPLES"     ] := ""
   FOR EACH cText IN ::docum_
      IF ! Empty( cText )
         hEntry[ "EXAMPLES" ] += cText + hb_eol()
      ENDIF
   NEXT
   hEntry[ "TESTS"        ] := ""
   hEntry[ "STATUS"       ] := "R"
   hEntry[ "COMPLIANCE"   ] := "Not Clipper compatible"
   hEntry[ "PLATFORMS"    ] := "Windows, Linux, Mac OS X, OS/2"
   hEntry[ "VERSION"      ] := cQT_VER + " or upper"
   hEntry[ "FILES"        ] := "Library: " + "hb" + cLib
#if 0
   hEntry[ "SEEALSO"      ] := ""
   hEntry[ "SEEALSO"      ] += iif( Empty( cInherits ), "", cInherits + "()" )
#endif

   RETURN hb_MemoWrit( ::cDOCFileName, __hbdoc_ToSource( { hEntry } ) )

/*----------------------------------------------------------------------*/

METHOD HbQtSource:parseVariables( cProto )
   LOCAL n, oMtd, oRet

   IF ( n := at( " ", cProto ) ) == 0
      RETURN .F.
   ENDIF

   oMtd := HbqtMethod():new()
   oMtd:cProto     := cProto
   oMtd:isVariable := .T.

   oMtd:cPre := cProto

   oMtd:cRet := AllTrim( SubStr( cProto, 1, n - 1 ) )
   oMtd:cFun := AllTrim( SubStr( cProto, n + 1    ) )

   oRet := HbqtArgument():new( oMtd:cRet, ::cQtObject, ::enum_, "const" $ oMtd:cPas, .T. )
   oMtd:oRet := oRet

   ::buildCppCode( oMtd )

   RETURN oMtd:lValid

/*----------------------------------------------------------------------*/

#define HBQTGEN_THIS_PROPER( s )   ( Upper( Left( s, 1 ) ) + SubStr( s, 2 ) )

METHOD HbQtSource:parseProto( cProto, fBody_ )
   LOCAL aArg, n, nn, cHBIdx, nIndex, s, ss, cFirstParamCast, cArg
   LOCAL oMtd, oRet, oArg, k, cKey, cVal
   LOCAL cRef

   IF ( n := at( "(", cProto ) ) == 0
      RETURN .F.
   ENDIF
   IF ( nn := rat( ")", cProto ) ) == 0
      RETURN .F.
   ENDIF

   /*                    Method Parsing                    */
   oMtd := HbqtMethod():new()
   oMtd:cProto := cProto
   oMtd:fBody_ := fBody_

   oMtd:cPre := AllTrim( SubStr( cProto,     1, n - 1      ) )
   oMtd:cPar := AllTrim( SubStr( cProto, n + 1, nn - 1 - n ) )
   oMtd:cPas := AllTrim( SubStr( cProto, nn + 1            ) )

   IF ( n := at( "[*", oMtd:cPas ) ) > 0
      IF ( nn := at( "*]", oMtd:cPas ) ) > 0
         oMtd:cMrk := AllTrim( SubStr( oMtd:cPas, n + 2, nn - n - 2 ) )
         oMtd:cPas := AllTrim( SubStr( oMtd:cPas, 1, n - 1 ) )
         FOR EACH k IN hb_aTokens( oMtd:cMrk, ";" )
            IF ( n := at( "=", k ) ) > 0
               cKey := AllTrim( SubStr( k, 1, n - 1 ) )
               cVal := AllTrim( SubStr( k, n + 1 ) )
               SWITCH Upper( cKey )
               CASE "D"
                  oMtd:nDetach := val( cVal )
                  EXIT
               CASE "A"
                  oMtd:nAttach := val( cVal )
                  EXIT
               CASE "V"
                  oMtd:cVersion := cVal
                  EXIT
               CASE "xxx"
                  EXIT
               ENDSWITCH
            ENDIF
         NEXT
      ENDIF
   ENDIF
   IF ( n := rat( " ", oMtd:cPre ) ) > 0
      oMtd:cFun := AllTrim( SubStr( oMtd:cPre, n + 1    ) )
      oMtd:cRet := AllTrim( SubStr( oMtd:cPre, 1, n - 1 ) )
   ELSE
      oMtd:cFun := oMtd:cPre
      oMtd:cRet := ""
   ENDIF
   IF Empty( oMtd:cRet ) .AND. oMtd:cFun == ::cQtObject
      oMtd:isConstructor := .T.
      oMtd:cRet := oMtd:cFun
   ENDIF

   /*                 Return Value Parsing                   */
   oRet := HbqtArgument():new( oMtd:cRet, ::cQtObject, ::enum_, "const" $ oMtd:cPas, .T. )
   oMtd:oRet := oRet

   IF ! Empty( oMtd:cPar )
      /*                 Arguments Parsing                      */
      aArg := hb_ATokens( oMtd:cPar, "," )
      AEval( aArg, {| e, i | aArg[ i ] := AllTrim( e ) } )

      FOR EACH cArg IN aArg
         nIndex := cArg:__enumIndex()

         oArg := HbqtArgument():new( cArg, ::cQtObject, ::enum_, .F., .F. )
         oMtd:hArgs[ nIndex ] := oArg

         oMtd:nHBIdx := nIndex // iif( oMtd:isConstructor, 0, 1 )
         cHBIdx := hb_ntos( oMtd:nHBIdx )
         oMtd:cDocNM := HBQTGEN_THIS_PROPER( oArg:cName )

         oMtd:nArgs++
         oMtd:nArgsOpt += iif( oArg:lOptional, 1, 0 )

         IF Empty( cFirstParamCast )
            cFirstParamCast := oArg:cCast
            IF "::" $ cFirstParamCast
               cFirstParamCast := SubStr( cFirstParamCast, at( "::", cFirstParamCast ) + 2 )
            ENDIF
         ENDIF

         cRef := NIL

         DO CASE
         CASE oArg:cCast == "..."
            oArg:cBody   := "..."
            oArg:cDoc    := "..."
            oArg:cTypeHB := "..."

         CASE oArg:cCast == "PHB_ITEM"
            oArg:cBody   := "hb_param( " + cHBIdx + ", HB_IT_ANY )"
            oArg:cDoc    := "x" + oMtd:cDocNM
            oArg:cTypeHB := "PB"

         CASE oArg:cCast == "T"
            oArg:cBody   := "hb_param( " + cHBIdx + ", HB_IT_ANY )"
            oArg:cDoc    := "x" + oMtd:cDocNM
            oArg:cTypeHB := "P"

         CASE oArg:cCast $ ::cInt .AND. oArg:lFar
            AAdd( oMtd:aPre, { oArg:cCast + " i" + oMtd:cDocNM + " = 0;", oMtd:nHBIdx, "i" + oMtd:cDocNM, "hb_storni" } )
            oArg:cBody   := "&i" + oMtd:cDocNM
            oArg:cDoc    := "@n" + oMtd:cDocNM
            oArg:cTypeHB := "N*"

         CASE oArg:cCast $ ::cIntLong .AND. oArg:lFar
            AAdd( oMtd:aPre, { oArg:cCast + " i" + oMtd:cDocNM + " = 0;", oMtd:nHBIdx, "i" + oMtd:cDocNM, "hb_stornl" } )
            oArg:cBody   := "&i" + oMtd:cDocNM
            oArg:cDoc    := "@n" + oMtd:cDocNM
            oArg:cTypeHB := "N*"

         CASE oArg:cCast $ ::cIntLongLong .AND. oArg:lFar
            AAdd( oMtd:aPre, { oArg:cCast + " i" + oMtd:cDocNM + " = 0;", oMtd:nHBIdx, "i" + oMtd:cDocNM, "hb_stornint" } )
            oArg:cBody   := "&i" + oMtd:cDocNM
            oArg:cDoc    := "@n" + oMtd:cDocNM
            oArg:cTypeHB := "N*"

         CASE oArg:cCast $ ::cInt
            IF ! Empty( oArg:cDefault ) .AND. !( oArg:cDefault == "0" )
               oArg:cBody := "hb_parnidef( " + cHBIdx + ", " + oArg:cDefault + " )"
            ELSE
               oArg:cBody := "hb_parni( " + cHBIdx + " )"
            ENDIF
            oArg:cDoc    := "n" + oMtd:cDocNM
            oArg:cTypeHB := "N"

         CASE oArg:cCast $ ::cIntLong
            IF ! Empty( oArg:cDefault ) .AND. !( oArg:cDefault == "0" )
               oArg:cBody := "hb_parnldef( " + cHBIdx + ", " + oArg:cDefault + " )"
            ELSE
               oArg:cBody := "hb_parnl( " + cHBIdx + " )"
            ENDIF
            oArg:cDoc    := "n" + oMtd:cDocNM
            oArg:cTypeHB := "N"

         CASE oArg:cCast $ "qlonglong,qulonglong"
            IF ! Empty( oArg:cDefault ) .AND. !( oArg:cDefault == "0" )
               oArg:cBody := "( " + oArg:cCast + " ) hb_parnintdef( " + cHBIdx + ", " + oArg:cDefault + " )"
            ELSE
               oArg:cBody := "( " + oArg:cCast + " ) hb_parnint( " + cHBIdx + " )"
            ENDIF
            oArg:cDoc    := "n" + oMtd:cDocNM
            oArg:cTypeHB := "N"

         CASE oArg:cCast $ ::cIntLongLong
            IF ! Empty( oArg:cDefault ) .AND. !( oArg:cDefault == "0" )
               oArg:cBody := "hb_parnintdef( " + cHBIdx + ", " + oArg:cDefault + " )"
            ELSE
               oArg:cBody := "hb_parnint( " + cHBIdx + " )"
            ENDIF
            oArg:cDoc    := "n" + oMtd:cDocNM
            oArg:cTypeHB := "N"

         CASE oArg:cCast $ "double,qreal" .AND. oArg:lFar
            AAdd( oMtd:aPre, { "qreal qr" + oMtd:cDocNM + " = 0;", oMtd:nHBIdx, "qr" + oMtd:cDocNM, "hb_stornd"  } )
            oArg:cBody   := "&qr" + oMtd:cDocNM
            oArg:cDoc    := "@n" + oMtd:cDocNM
            oArg:cTypeHB := "N*"

         CASE oArg:cCast $ "double,qreal,float"
            s := "hb_parnd( " + cHBIdx + " )"
            IF ! Empty( oArg:cDefault )
               oArg:cBody := "( HB_ISNUM( " + cHBIdx + " ) ? " + s + " : " + oArg:cDefault + " )"
            ELSE
               oArg:cBody := s
            ENDIF
            oArg:cDoc    := "n" + oMtd:cDocNM
            oArg:cTypeHB := "N"

         CASE oArg:cCast == "uchar" .AND. oArg:lFar .AND. ! oArg:lConst
            /* TOFIX: Such code is not valid and should never be generated (const->non-const) [vszakats] */
            oArg:cBody   := "( uchar * ) hb_parc( " + cHBIdx + " )"
            oArg:cDoc    := "c" + oMtd:cDocNM
            oArg:cTypeHB := "C"

         CASE oArg:cCast == "uchar" .AND. oArg:lFar .AND. oArg:lConst
            oArg:cBody   := "( const uchar * ) hb_parc( " + cHBIdx + " )"
            oArg:cDoc    := "c" + oMtd:cDocNM
            oArg:cTypeHB := "C"

         CASE oArg:cCast == "uchar" .AND. ! oArg:lFar .AND. ! oArg:lConst
            oArg:cBody   := "( uchar ) hb_parni( " + cHBIdx + " )"
            oArg:cDoc    := "n" + oMtd:cDocNM
            oArg:cTypeHB := "N"

         CASE oArg:cCast == "char" .AND. oArg:lFar .AND. ! oArg:lConst
            /* TOFIX: Such code is not valid and should never be generated (const->non-const) [vszakats] */
            oArg:cBody   := "( char * ) hb_parc( " + cHBIdx + " )"
            oArg:cDoc    := "c" + oMtd:cDocNM
            oArg:cTypeHB := "C"

         CASE oArg:cCast == "char" .AND. oArg:lFar .AND. oArg:lConst
            oArg:cBody   := "( const char * ) hb_parc( " + cHBIdx + " )"
            oArg:cDoc    := "c" + oMtd:cDocNM
            oArg:cTypeHB := "C"

         CASE oArg:cCast == "char" .AND. ! oArg:lFar .AND. ! oArg:lConst
            oArg:cBody   := "( char ) hb_parni( " + cHBIdx + " )"
            oArg:cDoc    := "n" + oMtd:cDocNM
            oArg:cTypeHB := "N"

         CASE ( "::" $ oArg:cCast ) .AND. oArg:lFar
            AAdd( oMtd:aPre, { oArg:cCast + " i" + oMtd:cDocNM + " = ( " + oArg:cCast + " ) 0;", oMtd:nHBIdx, "i" + oMtd:cDocNM, "hb_storni" } )
            oArg:cBody   := "&i" + oMtd:cDocNM
            oArg:cDoc    := "@n" + oMtd:cDocNM
            oArg:cTypeHB := "N"

         CASE ( "::" $ oArg:cCast )
            s := "( " + oArg:cCast + " ) hb_parni( " + cHBIdx + " )"
            IF ! Empty( oArg:cDefault ) .AND. !( oArg:cDefault == "0" )
               IF AScan( ::enum_, oArg:cDefault ) > 0
                  ss := ::cQtObject + "::" + oArg:cDefault
               ELSE
                  ss := iif( "::" $ oArg:cDefault, oArg:cDefault, ;
                     iif( isDigit( Left( oArg:cDefault, 1 ) ), oArg:cDefault, ::cQtObject + "::" + oArg:cDefault ) )
               ENDIF
               ss := "( " + oArg:cCast + " ) " + ss
               oArg:cBody := "( HB_ISNUM( " + cHBIdx + " ) ? " + s + " : " + ss + " )"
            ELSE
               oArg:cBody := s
            ENDIF
            oArg:cDoc    := "n" + oMtd:cDocNM
            oArg:cTypeHB := "N"

         CASE oArg:cCast == "bool" .AND. oArg:lFar
            AAdd( oMtd:aPre, { "bool i" + oMtd:cDocNM + " = 0;", oMtd:nHBIdx, "i" + oMtd:cDocNM, "hb_stornl" } )
            oArg:cBody   := "&i" + oMtd:cDocNM
            oArg:cDoc    := "@l" + oMtd:cDocNM
            oArg:cTypeHB := "L"

         CASE oArg:cCast == "bool"
            s := "hb_parl( " + cHBIdx + " )"
            IF ! Empty( oArg:cDefault )
               oArg:cBody := iif( oArg:cDefault == "false", s, "hb_parldef( " + cHBIdx + ", true )" )
            ELSE
               oArg:cBody := s
            ENDIF
            oArg:cDoc    := "l" + oMtd:cDocNM
            oArg:cTypeHB := "L"

         CASE oArg:cCast == "QString"
            oArg:cBody   := "hb_parstr_utf8( " + cHBIdx + ", &pText%%%, NULL )"
            oArg:cDoc    := "c" + oMtd:cDocNM  // oArg:cCast - W R O N G
            oArg:cTypeHB := "C"
#if 0
         CASE oArg:cCast == "FT_Face"
            oArg:cBody   := "hbqt_par_FT_Face( " + cHBIdx + " )"
            oArg:cDoc    := "c" + oMtd:cDocNM
            oArg:cTypeHB := "C"
#endif
         CASE oArg:cCast == "QIcon"
            cRef := "QIcon"
            s := "*hbqt_par_QIcon( " + cHBIdx + " )"
            oArg:cBody   := "( HB_ISCHAR( " + cHBIdx + " ) ? " + "QIcon( hbqt_par_QString( " + cHBIdx + " ) )" + " : " + s + ")"
            oArg:cDoc    := "co" + oArg:cCast
            oArg:cTypeHB := "CO"

         CASE oArg:lFar
            cRef := oArg:cCast
            oArg:cBody := "hbqt_par_" + oArg:cCast + "( " + cHBIdx + " )"
            IF ! Empty( oArg:cDefault )
               oArg:cBody := "( HB_ISOBJECT( " + cHBIdx + " ) ? " + oArg:cBody + " : " + oArg:cDefault + " )"
            ENDIF
            oArg:cDoc    := "o" + oArg:cCast
            oArg:cTypeHB := "O"

         CASE oArg:lAnd .AND. oArg:lConst
            cRef := oArg:cCast
            s := "*hbqt_par_" + oArg:cCast + "( " + cHBIdx + " )"
            IF ! Empty( oArg:cDefault ) .AND. ( "(" $ oArg:cDefault )
               oArg:cBody := "( HB_ISOBJECT( " + cHBIdx + " ) ? " + s + " : " + oArg:cDefault + " )"
            ELSE
               oArg:cBody := s
            ENDIF
            oArg:cDoc    := "o" + oArg:cCast
            oArg:cTypeHB := "O"

         CASE oArg:lAnd
            cRef := oArg:cCast
            oArg:cBody   := "*hbqt_par_" + oArg:cCast + "( " + cHBIdx + " )"
            oArg:cDoc    := "o" + oArg:cCast
            oArg:cTypeHB := "O"

         CASE oArg:cCast == "QChar"
            cRef := oArg:cCast
            oArg:cBody   := "*hbqt_par_" + oArg:cCast + "( " + cHBIdx + " )"
            oArg:cDoc    := "o" + oArg:cCast
            oArg:cTypeHB := "O"

         OTHERWISE
            oArg:cBody   := ""   /* Just in case */
            oArg:cDoc    := ""
            oArg:cTypeHB := ""

         ENDCASE

         hbqtgen_AddRef( ::hRef, cRef )

         oMtd:cParas += oArg:cBody + ", "
         oMtd:cDocs  += oArg:cDoc + ", "
      NEXT
   ENDIF

   oMtd:nArgsReal := oMtd:nArgs - oMtd:nArgsOpt

   FOR EACH oArg IN oMtd:hArgs
      IF ( Left( oArg:cCast, 1 ) == "Q" .OR. Left( oArg:cCast, 3 ) == "HBQ" ) .AND. ;
                                            ! ( oArg:cCast $ "QString,QRgb" ) .AND. ;
                                            ! ( "::" $ oArg:cCast )
         oMtd:nArgQCast := oArg:__enumIndex()
         EXIT
      ENDIF
   NEXT
   FOR EACH oArg IN oMtd:hArgs
      IF oArg:cTypeHB $ "O"
         oMtd:nArgHBObj := oArg:__enumIndex()
         EXIT
      ENDIF
   NEXT

   IF right( oMtd:cParas, 2 ) == ", "
      oMtd:cParas := SubStr( oMtd:cParas, 1, Len( oMtd:cParas ) - 2 )
      oMtd:cDocs  := SubStr( oMtd:cDocs , 1, Len( oMtd:cDocs  ) - 2 )
   ENDIF

   ::buildCppCode( oMtd )

   RETURN oMtd:lValid

/*----------------------------------------------------------------------*/

STATIC PROCEDURE hbqtgen_AddRef( hRef, cRef )

   IF ! Empty( cRef ) .AND. !( ">" $ cRef ) .AND. !( cRef $ "uchar|QString|QRgb|Bool|char" )
      hRef[ cRef ] := NIL
   ENDIF

   RETURN

/*----------------------------------------------------------------------*/

METHOD HbQtSource:buildCppCode( oMtd )
   LOCAL oRet   := oMtd:oRet
   LOCAL cPara  := oMtd:cParas
   LOCAL cRef, cRefInList

   oMtd:cWdg      := "hbqt_par_" + ::cQtObject + "( 1 )->"
   oMtd:cParas    := iif( oMtd:isVariable(), "", "( " + oMtd:cParas + " )" )
   oMtd:cCmn      := oMtd:cWdg + oMtd:cFun + oMtd:cParas
   oMtd:cDocNMRet := HBQTGEN_THIS_PROPER( oRet:cName )

   DO CASE
   CASE oMtd:isConstructor
      oMtd:cCmd := "hbqt_create_objectGC( hbqt_gcAllocate_" + ::cQtObject + "( new " + oRet:cCast + "( " + cPara + " ), true )" + ', "HB_' + Upper(::cQtObject) +'")'
      oMtd:cPrgRet := "o" + ::cQtObject

   CASE "<" $ oRet:cCast
      DO CASE
      CASE ! ( "QList" $ oRet:cCast )
         oMtd:cCmd := ""
         oMtd:cPrgRet := ""
      CASE "::" $ oRet:cCast
         oMtd:cCmd := ""
         oMtd:cPrgRet := ""
      CASE "QPair" $ oRet:cCast
         oMtd:cCmd := ""
         oMtd:cPrgRet := ""
      CASE "<T>" $ oRet:cCast
         oMtd:cCmd := ""
         oMtd:cPrgRet := ""
      OTHERWISE
         cRef := "QList"
         cRefInList := StrTran( oRet:cCast, "QList<" )
         cRefInList := StrTran( cRefInList, ">" )
         cRefInList := StrTran( cRefInList, "*" )
         cRefInList := StrTran( cRefInList, " " )
         oMtd:isRetList := .T.
         oMtd:cCmd := "hbqt_create_objectGC( hbqt_gcAllocate_QList( new " + oRet:cCast + "( " + oMtd:cCmn + " ), true ) " + ', "HB_' + Upper( ::cQtObject ) + '" )'
         oMtd:cPrgRet := "o" + oMtd:cDocNMRet
      ENDCASE

   CASE oRet:cCast == "T"
      oMtd:cCmd := "hb_itemReturn( " + oMtd:cCmn + " )"
      oMtd:cPrgRet := "o" + oMtd:cDocNMRet

   CASE oRet:cCast == "void"
      oMtd:cCmd := oMtd:cCmn
      oMtd:cPrgRet := "NIL"

   CASE oRet:cCast $ ::cInt
      oMtd:cCmd := "hb_retni( " + oMtd:cCmn + " )"
      oMtd:cPrgRet := "n" + oMtd:cDocNMRet

   CASE oRet:cCast $ ::cIntLong
      oMtd:cCmd := "hb_retnl( " + oMtd:cCmn + " )"
      oMtd:cPrgRet := "n" + oMtd:cDocNMRet

   CASE oRet:cCast $ ::cIntLongLong
      oMtd:cCmd := "hb_retnint( " + oMtd:cCmn + " )"
      oMtd:cPrgRet := "n" + oMtd:cDocNMRet

   CASE oRet:cCast $ "double,qreal,float"
      oMtd:cCmd := "hb_retnd( " + oMtd:cCmn + " )"
      oMtd:cPrgRet := "n" + oMtd:cDocNMRet

   CASE "::" $ oRet:cCast
      oMtd:cCmd := "hb_retni( ( " + oRet:cCast + " ) " + oMtd:cCmn + " )"
      oMtd:cPrgRet := "n" + oMtd:cDocNMRet

   CASE oRet:cCast == "bool"
      oMtd:cCmd := "hb_retl( " + oMtd:cCmn + " )"
      oMtd:cPrgRet := "l" + oMtd:cDocNMRet

   CASE oRet:cCast == "char" .AND. oRet:lFar
      oMtd:cCmd := "hb_retc( " + oMtd:cCmn + " )"
      oMtd:cPrgRet := "c" + oMtd:cDocNMRet

   CASE oRet:cCast == "char"
      oMtd:cCmd := "hb_retni( " + oMtd:cCmn + " )"
      oMtd:cPrgRet := "c" + oMtd:cDocNMRet

   CASE oRet:cCast == "QString"
      oMtd:cCmd := "hb_retstr_utf8( " + oMtd:cCmn + ".toUtf8().data()" + " )"
      oMtd:cPrgRet := "c" + oMtd:cDocNMRet

   CASE oRet:cCast == "FT_Face"
      oMtd:cCmd := "hb_retc( " + oMtd:cCmn + " )"
      oMtd:cPrgRet := "c" + oMtd:cDocNMRet

   CASE oRet:lFar .AND. ( oRet:cCast $ "uchar" )
      oMtd:cCmd := "hb_retc( ( const char * ) " + oMtd:cCmn + " )"
      oMtd:cPrgRet := "c" + oMtd:cDocNMRet

   CASE oRet:lFar .AND. ! oRet:lConst
      cRef := oRet:cCast
      oMtd:cCmd := hbqtgen_Get_Command( oRet:cCast, oMtd:cCmn, .F. )
      oMtd:cPrgRet := "o" + oMtd:cDocNMRet

   CASE hbqtgen_isAqtObject( oRet:cCast )  .AND. ;
                             oRet:lFar     .AND. ;
                             oRet:lConst   .AND. ;
                             "Abstract" $ oRet:cCast
      cRef := oRet:cCast
      oMtd:cCmd := "hbqt_create_objectGC( hbqt_gcAllocate_" + oRet:cCast + "( ( void * ) " + oMtd:cCmn + ", false ) " + ', "HB_' + Upper( ::cQtObject ) + '" )'
      oMtd:cPrgRet := "o" + oMtd:cDocNMRet

   CASE hbqtgen_isAqtObject( oRet:cCast )  .AND. ;
                             oRet:lFar     .AND. ;
                             oRet:lConst   .AND. ;
                             oRet:lVirt
      cRef := oRet:cCast
      oMtd:cCmd := "hbqt_create_objectGC( hbqt_gcAllocate_" + oRet:cCast + "( ( void * ) " + oMtd:cCmn + ", false ) " + ', "HB_' + Upper( ::cQtObject ) + '" )'
      oMtd:cPrgRet := "o" + oMtd:cDocNMRet

   CASE hbqtgen_isAqtObject( oRet:cCast )  .AND. ;
                             oRet:lFar     .AND. ;
                             oRet:lConst   .AND. ;
                             oRet:lConstL
      cRef := oRet:cCast
      oMtd:cCmd := hbqtgen_Get_Command_1( oRet:cCast, oMtd:cCmn )
      oMtd:cPrgRet := "o" + oMtd:cDocNMRet

   CASE oRet:lAnd .AND. oRet:lConst
      cRef := oRet:cCast
      oMtd:cCmd := hbqtgen_Get_Command( oRet:cCast, oMtd:cCmn )
      oMtd:cPrgRet := "o" + oMtd:cDocNMRet

   CASE oRet:lConst
      cRef := oRet:cCast
      oMtd:cCmd := hbqtgen_Get_Command( oRet:cCast, oMtd:cCmn )
      oMtd:cPrgRet := "o" + oMtd:cDocNMRet

   CASE oRet:lAnd
      cRef := oRet:cCast
      oMtd:cCmd := hbqtgen_Get_Command( oRet:cCast, oMtd:cCmn )
      oMtd:cPrgRet := "o" + oMtd:cDocNMRet

   OTHERWISE
      /* No attribute is attached to return value */
      IF hbqtgen_isAqtObject( oRet:cCast )
         cRef := oRet:cCast
         oMtd:cCmd := hbqtgen_Get_Command( oRet:cCast, oMtd:cCmn )
         oMtd:cPrgRet := "o" + oMtd:cDocNMRet
      ELSE
         oMtd:cError := "<<< " + oMtd:cProto + " | " + oRet:cCast + " >>>"
         oMtd:cCmd := ""
         oMtd:cPrgRet := ""
      ENDIF
   ENDCASE

   /* Lists to be disabled in parameters - TODO */
   IF "<" $ oMtd:cPar
      oMtd:cCmd := ""
   ENDIF

   IF ( oMtd:lValid := ! Empty( oMtd:cCmd ) )
      AAdd( ::aMethods, oMtd )
      hbqtgen_AddRef( ::hRef, cRef )
      IF ! Empty( cRefInList ) .AND. ! ( cRefInList $ "int,qreal" )
         hbqtgen_AddRef( ::hRef, cRefInList )
      ENDIF
   ENDIF

   RETURN Self

/*----------------------------------------------------------------------*/
//                          Class HbqtMethod
/*----------------------------------------------------------------------*/

CREATE CLASS HbqtMethod

   VAR    name                                    INIT ""   //  widget
   VAR    isVariable                              INIT .F.
   VAR    lValid                                  INIT .T.
   VAR    nSiblings                               INIT 0    //  names post_fixed by number
   VAR    isSibling                               INIT .F.  //  is nother function with same name
   VAR    isConstructor                           INIT .F.
   VAR    areFuncClubbed                          INIT .T.
   VAR    isRetList                               INIT .F.

   VAR    cProto                                  INIT ""   //  QWidget * widget ( QWidget * parent, const QString & name ) const  [*D=4*]

   VAR    cPre                                    INIT ""   //  ^^^^^^^^^^^^^^^^
   VAR    cPar                                    INIT ""   //                     ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
   VAR    cPas                                    INIT ""   //                                                              ^^^^^
   VAR    cMrk                                    INIT ""   //                                                                       ^^^

   VAR    nDetach                                 INIT 0
   VAR    nAttach                                 INIT 0
   VAR    cVersion                                INIT ""

   VAR    cFun                                    INIT ""
   VAR    cRet                                    INIT ""

   VAR    cParas                                  INIT ""
   VAR    cParasN                                 INIT ""
   VAR    cDocs                                   INIT ""

   VAR    cDoc                                    INIT ""   // Qt_QWidget_setSize_1( nWidth, nHeight ) -> NIL

   VAR    cError                                  INIT ""
   VAR    cCmd                                    INIT ""
   VAR    cCmdN                                   INIT ""
   VAR    cCmn                                    INIT ""
   VAR    cCmnN                                   INIT ""
   VAR    cDocNM                                  INIT ""
   VAR    cDocNMRet                               INIT ""
   VAR    cPrgRet                                 INIT ""
   VAR    cWdg                                    INIT ""
   VAR    cHBFunc                                 INIT ""

   VAR    aPre                                    INIT {}
   VAR    aPreN                                   INIT {}
   VAR    nHBIdx
   VAR    nHBIdxN
   VAR    nArgQCast                               INIT 0    //  First argument position of type Q*Class
   VAR    nArgHBObj                               INIT 0    //  First argument position of type Q*Class

   VAR    oRet
   VAR    nArgs                                   INIT 0    //  Number of arguments contained
   VAR    nArgsOpt                                INIT 0    //  Number of optional arguments contained
   VAR    nArgsReal                               INIT 0    //  Number of minimum arguments to be supplied

   VAR    hArgs                                   INIT { => }

   VAR    fBody_                                  INIT {}

   VAR    cMtdDef
   VAR    cMtdCall

   METHOD new()

ENDCLASS

/*----------------------------------------------------------------------*/

METHOD HbqtMethod:new()
   hb_hKeepOrder( ::hArgs, .T. )
   RETURN Self

/*----------------------------------------------------------------------*/
//                         Class HbqtArgument
/*----------------------------------------------------------------------*/

CREATE CLASS HbqtArgument

   VAR    cRaw
   VAR    cNormal
   VAR    cName
   VAR    cCast                                INIT ""
   VAR    cBody
   VAR    cBodyN
   VAR    cDoc

   VAR    lRet                                 INIT .F.

   VAR    cTypeHb
   VAR    cTypeQt
   VAR    cObject

   VAR    lConst                               INIT .F.
   VAR    lAnd                                 INIT .F.
   VAR    lFar                                 INIT .F.
   VAR    lVirt                                INIT .F.
   VAR    lConstL                              INIT .F.

   VAR    lList                                INIT .F.

   VAR    lOptional                            INIT .F.
   VAR    cDefault

   METHOD new( cTxt, cQtObject, enum_, lConstL, lIsRetArg )

ENDCLASS

/*----------------------------------------------------------------------*/

METHOD HbqtArgument:new( cTxt, cQtObject, enum_, lConstL, lIsRetArg )
   LOCAL n

   ::cRaw    := cTxt
   ::lRet    := lIsRetArg
   ::lList   := "<" $ cTxt

   ::lConst  := "const"   $ cTxt
   ::lAnd    := "&"       $ cTxt
   ::lFar    := "*"       $ cTxt
   ::lVirt   := "virtual" $ cTxt
   ::lConstL := lConstL

   IF ( n := at( "=", cTxt ) ) > 0
      ::cDefault  := AllTrim( SubStr( cTxt, n + 1 ) )
      ::lOptional := .T.
      cTxt := SubStr( cTxt, 1, n - 1 )
   ENDIF

   cTxt := StrTran( cTxt, "virtual " )
   cTxt := StrTran( cTxt, "const "   )
   cTxt := StrTran( cTxt, "   "     , " " )
   cTxt := StrTran( cTxt, "  "      , " " )
   IF ! ::lList
      cTxt := StrTran( cTxt, "& " )
      cTxt := StrTran( cTxt, "&"  )
      cTxt := StrTran( cTxt, "* " )
      cTxt := StrTran( cTxt, "*"  )
   ENDIF
   ::cNormal := cTxt := AllTrim( cTxt )

   IF ::lList
      ::cCast := cTxt
      ::cName := ::cCast
   ELSE
      IF ( n := at( " ", cTxt ) ) > 0
         ::cCast := SubStr( cTxt, 1, n - 1 )
         ::cName := SubStr( cTxt, n + 1 )
      ELSE
         ::cCast := cTxt
         ::cName := cTxt
      ENDIF
   ENDIF

   IF AScan( enum_, {| e | iif( Empty( e ), .F., e == ::cCast ) } ) > 0
      ::cCast := cQtObject + "::" + ::cCast
   ENDIF

   RETURN Self

/*----------------------------------------------------------------------*/
//                        Helper Functions
/*----------------------------------------------------------------------*/

STATIC FUNCTION hbqtgen_Get_Command_1( cWgt, cCmn )
   RETURN "hbqt_create_objectGC( hbqt_gcAllocate_" + cWgt + "( new " + cWgt + "( *( " + cCmn + " ) ), true ) , " + '"HB_' + Upper( cWgt ) +'")'

/*----------------------------------------------------------------------*/

STATIC FUNCTION hbqtgen_Get_Command( cWgt, cCmn, lNew )

   IF lNew == NIL
      lNew := .T.
   ENDIF

   IF lNew
      RETURN "hbqt_create_objectGC( hbqt_gcAllocate_" + cWgt + "( new " + cWgt + "( " + cCmn + " ), true ) , " + '"HB_' + Upper( cWgt ) +'" )'
   ELSE
      RETURN "hbqt_create_objectGC( hbqt_gcAllocate_" + cWgt + "( " + cCmn + ", false ) , " + '"HB_' + Upper( cWgt ) +'" )'
   ENDIF
   RETURN ""

/*----------------------------------------------------------------------*/

STATIC FUNCTION hbqtgen_PullOutSection( cQth, cSec )
   LOCAL cTxt, n, nn, cTknB, cTknE
   LOCAL a_:={}

   cTknB := "<" + cSec + ">"
   cTknE := "</" + cSec + ">"

   IF ( n := at( cTknB, cQth ) ) > 0
      IF( nn := at( cTknE, cQth ) ) > 0
         cTxt := SubStr( cQth, n + Len( cTknB ), nn - 1 - ( n + Len( cTknB ) ) )
      ENDIF
      IF ! Empty( cTxt )
         a_:= hb_ATokens( cTxt, Chr( 10 ) )
      ENDIF
   ENDIF

   RETURN a_

/*----------------------------------------------------------------------*/

STATIC FUNCTION hbqtgen_PullOutFuncBody( protos_, nFrom )
   LOCAL s, nTo := 0,  a_:= {}

   FOR EACH s IN protos_
      IF s:__enumIndex() > nFrom
         IF Left( s, 1 ) == "}"
            nTo := s:__enumIndex()
            EXIT
         ENDIF
      ENDIF
   NEXT
   IF nTo > nFrom
      FOR EACH s IN protos_
         IF s:__enumIndex() > nFrom .AND. s:__enumIndex() < nTo
            AAdd( a_, s )
            s := ""
         ENDIF
      NEXT
   ENDIF

   RETURN a_

/*----------------------------------------------------------------------*/

STATIC FUNCTION hbqtgen_isAqtObject( cCast )
   RETURN Left( cCast, 1 ) == "Q" .OR. Left( cCast, 3 ) == "HBQ"

/*----------------------------------------------------------------------*/

STATIC FUNCTION hbqtgen_CreateTarget( cFile, txt_ )
   LOCAL cContent := ""

   AEval( txt_, {| e | cContent += RTrim( e ) + hb_eol() } )

   RETURN hb_MemoWrit( cFile, cContent )

/*----------------------------------------------------------------------*/

STATIC FUNCTION hbqtgen_BuildCopyrightText()
   LOCAL txt_ := {}

   AAdd( txt_, "/* WARNING: Automatically generated source file. DO NOT EDIT! */"              )
   AAdd( txt_, ""                                                                              )
   AAdd( txt_, "/* Harbour QT wrapper"                                                         )
   AAdd( txt_, "   Copyright 2009-2012 Pritpal Bedi <bedipritpal@hotmail.com>"                 )
   AAdd( txt_, "   www - http://harbour-project.org */"                                        )
   AAdd( txt_, ""                                                                              )
   AAdd( txt_, '#include "hbqt.h"'                                                             )
   AAdd( txt_, '#include "hbapiitm.h"'                                                         )
   AAdd( txt_, '#include "hbvm.h"'                                                             )
   AAdd( txt_, '#include "hbapierr.h"'                                                         )
   AAdd( txt_, '#include "hbstack.h"'                                                          )
   AAdd( txt_, '#include "hbdefs.h"'                                                           )
   AAdd( txt_, '#include "hbapicls.h"'                                                         )
   AAdd( txt_, ""                                                                              )
   AAdd( txt_, "#if QT_VERSION >= 0x040500"                                                    )
   AAdd( txt_, ""                                                                              )

   RETURN txt_

/*----------------------------------------------------------------------*/

STATIC PROCEDURE hbqtgen_BuildFooter( txt_ )

   AAdd( txt_, "#endif" )

   RETURN

/*----------------------------------------------------------------------*/

STATIC FUNCTION hbqtgen_stripLastFrom( cStr, cDlm )
   LOCAL n
   IF ( n := rAt( cDlm, cStr ) ) > 0
      RETURN SubStr( cStr, 1, n - 1 )
   ENDIF
   RETURN cStr

/*----------------------------------------------------------------------*/

STATIC FUNCTION __TY( oM, nArgs )
   LOCAL i, s := ""
   FOR i := 1 TO nArgs
      s += PadR( oM:hArgs[ i ]:cTypeHB, 3 )
   NEXT
   RETURN s

/*----------------------------------------------------------------------*/

STATIC FUNCTION __TY_Method( oMtd, nArgs )
   LOCAL nArg, oArg, aIdx := {}, cRet

   FOR EACH oArg IN oMtd:hArgs
      IF oArg:__enumIndex() >= oMtd:nArgQCast
         IF ! ( "::" $ oArg:cCast ) .AND. ! ( oArg:cCast == "QString" ) .AND. ( Left( oArg:cCast, 1 ) == "Q" )
            AAdd( aIdx, oArg:__enumIndex() )
         ENDIF
      ENDIF
      IF oArg:__enumIndex() == nArgs
         EXIT
      ENDIF
   NEXT

   cRet := ""
   FOR EACH nArg IN aIdx
      cRet += "hbqt_par_isDerivedFrom( " + hb_ntos( nArg ) + ', "' + upper( oMtd:hArgs[ nArg ]:cCast ) + '" )' + " && "
   NEXT
   cRet := SubStr( cRet, 1, Len( cRet ) - 4 )

   RETURN cRet

/*----------------------------------------------------------------------*/

STATIC FUNCTION qth_is_extended( cQTHFileName )
   LOCAL lYes := .F.
   LOCAL cQth, aTkn, n, s, class_, cls_:= {}

   cQth := hb_MemoRead( cQTHFileName )

   /* Prepare to be parsed properly */
   IF !( hb_eol() == Chr( 10 ) )
      cQth := StrTran( cQth, hb_eol(), Chr( 10 ) )
   ENDIF
   IF !( hb_eol() == Chr( 13 ) + Chr( 10 ) )
      cQth := StrTran( cQth, Chr( 13 ) + Chr( 10 ), Chr( 10 ) )
   ENDIF

   IF ! Empty( class_:= hbqtgen_PullOutSection( @cQth, "CLASS" ) )
      FOR EACH s IN class_
         IF ( n := at( "=", s ) ) > 0
            AAdd( cls_, { Upper( AllTrim( SubStr( s, 1, n - 1 ) ) ), Upper( AllTrim( SubStr( s, n + 1 ) ) ) } )
         ENDIF
      NEXT
   ENDIF

   FOR EACH aTkn IN cls_
      IF aTkn[ 1 ] $ "PAINTEVENT,xxx"
         IF aTkn[ 2 ] == "YES"
            lYes := .T.
         ENDIF
      ENDIF
   NEXT

   RETURN lYes

/*----------------------------------------------------------------------*/