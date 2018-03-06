.686 
.model flat,stdcall 
option casemap:none
WinMain proto :DWORD,:DWORD,:DWORD,:DWORD

include \masm32\include\windows.inc 
include \masm32\include\gdi32.inc
include \masm32\include\user32.inc 
include \masm32\include\kernel32.inc 

includelib \masm32\lib\gdi32.lib
includelib \masm32\lib\user32.lib 
includelib \masm32\lib\kernel32.lib
include masm32.inc
includelib masm32.lib

.const

largeur	equ	800
hauteur	equ	800

.data 
ps	PAINTSTRUCT	<0>
hdc	HDC	0
ClassName	db "Parent Claas Name",0
ClassName_F db "SimpleWinClass",0 	; classe de type SimpleWinClass (fenêtre simple)
AppName  db "Le meilleur de tous les moteurs graphiques !",0 

	
	;tableau contenant les coordonnées des points
	objet			 REAL8 	-100.0, -100.0, -100.0,
				 			 100.0, -100.0, -100.0,
				 			 100.0,  100.0, -100.0,
							-100.0,  100.0, -100.0,
				 			 100.0, -100.0,  100.0,
							-100.0, -100.0,  100.0,
							-100.0,  100.0,  100.0,
						 	 100.0,  100.0,  100.0

	;tableau contenant les différentes faces
	faces 			BYTE    0,1,2,3,0,
							1,4,7,2,1,
							3,2,7,6,3,
							4,5,6,7,4,
							5,0,3,6,5,
							5,4,1,0,5
	
	disfoc 			REAL8 900.0					; distance focale
	counterFace		DWORD 0
	PI 				REAL8 3.1415926535
	centQuatreVing 	REAL8 180.0					
	
	
	
	
	Xoff 			REAL8 400.0					; Position de X dans l'affichage
	Yoff 			REAL8 400.0					; Position de Y dans l'affichage					
	Zoff 			REAL8 200.0					; Zoom dans l'affichage
	
	XrotDeg			REAL8 45.0					; Rotation sur l'axe X en degrès
	YrotDeg			REAL8 45.0					; Rotation sur l'axe Y en degrès
	ZrotDeg			REAL8 0.0					; Rotation sur l'axe Z en degrès

							
.data? 

hInstance HINSTANCE ? 
CommandLine LPSTR ? 

points2D REAL8 16 dup(?)

	Xrot		REAL8 ?
	Yrot		REAL8 ?
	Zrot		REAL8 ?


.const 

.code

	DegVersRadian PROC												; objectif de la fonction : transformer les degrès en radian
																	; avec la formule Radian = Degres * Pi / 180
		fld XrotDeg													; On transforme XrotDeg, YrotDeg et ZrotDeg (degres) en 
		fmul PI						; * pi							; 				Xrot, Yrot, Zrot (radian)
		fdiv centQuatreVing			; /180		
		fstp Xrot
		
		fld YrotDeg
		fmul PI						; * pi
		fdiv centQuatreVing			; /180		
		fstp Yrot
		
		fld ZrotDeg
		fmul PI						; * pi
		fdiv centQuatreVing			; /180		
		fstp Zrot
		
		ret

	DegVersRadian endp

	calculProjection PROC 											; objectif de la fonction : transformer des coordonnées 3D en coordonnées 2D
	
	
	mov eax,0 	; compteur qui parcourt objet[] et récupère les coordonnées X puis Y
	mov ebx,2	; compteur qui parcourt objet[] et récupère la coordonnées Z
	mov ecx,0	; compteur qui parcourt points2D[] pour ranger les coordonnées 2D obtenues
	
	boucleCalcul3D:

	;caculX'
		fld objet[eax * REAL8]
		fmul disfoc						; df * X dans ST(0)
	
		fld disfoc						; df dans ST(0)
		fadd objet[ebx * REAL8]			; df + Z dans ST(0) 
		fadd Zoff						; df + Z + Zoff dans ST(0)
	
		fdivp ST(1), ST(0)				; (df * X) / (df + Z + Zoff) dans ST(0)
	
		fadd Xoff						; (df * X) / (df + Z + Zoff) + Xoff
	
		fstp points2D[ecx * REAL8]		; Fin de calcul et on range X'
	
	inc eax								
	inc ecx	
	
	;caculY'
		fld objet[eax * REAL8]			; on récupére la coordonnée de Y dans objet[]
		fmul disfoc						; df * Y dans ST(0)
	
		fld disfoc						; df dans ST(0)
		fadd objet[ebx * REAL8]			; df + Z dans ST(0) 
		fadd Zoff						; df + Z + Zoff dans ST(0)
	
		fdivp ST(1), ST(0)				; (df * Y) / (df + Z + Zoff) dans ST(0)
	
		fadd Yoff						; (df * Y) / (df + Z + Zoff) + Yoff
	
		fstp points2D[ecx * REAL8] 		; Fin de calcul et on range X'
		
		
	
	inc eax								; on incrément 2 fois car on saute la cordonnée Z			(pour atteindre la coordonnée X suivante)
	inc eax
	
	inc ebx								; on incrémente 3 fois car on saute les coordonnées X et Y (pour atteindre la coordonnée Z suivante)
	inc ebx
	inc ebx
	
	inc ecx								; on incrémente pour ranger dans a la case suivante de points2D[]
	
	cmp ecx, 15
	jb boucleCalcul3D					; on boucle sur le compteur de tableau de points2D[], il doit contenir 16 cases (8 coordonnées X + 8 coordonées Y)
		

	RET

calculProjection ENDP

	rotationX proc													; objectif de la fonction : calculer les coordonnées des points du cube 3D après une rotation sur l'axe X
LOCAL X:REAL8, Y:REAL8, Z:REAL8		;X', Y', Z'

	
	mov eax, 0	;compteur dans objet[] pour la lecture
	mov ebx, 0	;compteur dans objet[] pour l'écriture		
	
	RotationX:
	
		fld objet[eax * REAL8]	; on récupère la coordonnée X du point
		fstp X
		inc eax
		
		fld objet[eax * REAL8]	; on récupère la coordonnée Y du point
		fstp Y
		inc eax
		
		fld objet[eax * REAL8] ; on récupère la coordonnée Z du point
		fstp Z
		inc eax
		
		
		
	
		;X
			inc	ebx						; aucun changement, on passe à la case suivante

		;Y
			fld Xrot
			fcos						; cos(Xrot) dans ST(0)
			fmul Y  		    		; Y * cos(Xrot) dans ST(0)
			fld	Xrot       				; X dans ST(0)
			Fsin						; sin(Xrot) dans ST(0)
			fmul Z 						; Z * sin(Xrot) dans ST(0)
			fsubp ST(1), ST(0)			; Y * cos(X) - Z * sin(Xrot) dans ST(0)
			fstp objet[ebx * REAL8]		; Y' dans objet[]
			inc ebx

		;Z
			fld Xrot 					; X dans ST(0)
			fsin 						; sin(Xrot) dans ST(0)
			fmul Y  					; Y * sin(Xrot) dans ST(0)
			fld Xrot					; X dans ST(0)
			fcos 						; cos(Xrot) dans ST(0)
			fmul Z 						; Z * cos(Xrot) dans ST(0)
			faddp ST(1), ST(0) 			; Y * sin(Xrot) + Z * cos(Xrot) dans ST(0)
			fstp objet[ebx * REAL8]		; Z' dans objet[]
			inc ebx
	
			cmp eax, 23
			jb RotationX				; on réalise cette étape pour les 24 points du tableau objet[]
	
	
	
	ret

rotationX endp

	rotationY proc													; objectif de la fonction : calculer les coordonnées des points du cube 3D après une rotation sur l'axe Y
LOCAL X:REAL8, Y:REAL8, Z:REAL8		;X', Y', Z'

	
	mov eax, 0	;compteur dans objet[] pour la lecture
	mov ebx, 0	;compteur dans objet[] pour l'écriture	
	
	RotationY:
	
		fld objet[eax * REAL8]			; on récupère la coordonnée X du point
		fstp X
		inc eax
		
		fld objet[eax * REAL8]			; on récupère la coordonnée Y du point
		fstp Y
		inc eax
		
		fld objet[eax * REAL8]			; on récupère la coordonnée Z du point
		fstp Z
		inc eax
		
		;X
			fld Yrot					; Yrot dans ST(0)
			fsin 						; sin(Yrot) dans ST(0)
			fmul Z  					; Z * sin(Yrot) dans ST(0)
			fld Yrot					; Yrot dans ST(0)
			fcos 						; cos(Yrot) dans ST(0)
			fmul X 						; X * cos(Yrot) dans ST(0)
			faddp ST(1), ST(0) 			; Z * sin(Yrot) + X * cos(Yrot) dans ST(0)
			fstp objet[ebx * REAL8]		; X' dans objet[]
			inc ebx

		;Y
			inc ebx						; aucun changement, on passe à la case suivante

		;Z
			fld Yrot 					; Yrot dans ST(0)
			fcos						; cos(Yrot) dans ST(0)
			fmul Z  			    	; Z * cos(Yrot) dans ST(0)
			fld	Yrot	       			; Yrot dans ST(0)
			Fsin						; sin(Yrot) dans ST(0)
			fmul X 						; X * sin(Xrot) dans ST(0)
			fsubp ST(1), ST(0)			; Z * cos(Yrot) -  X * sin(Xrot) dans ST(0)
			fstp objet[ebx * REAL8]		; Z' dans objet[]
			inc ebx
		
	
			cmp eax, 23
			jb RotationY				; on réalise cette étape pour les 24 points du tableau objet[]
	
	
	
	ret

rotationY endp

	rotationZ proc													; objectif de la fonction : calculer les coordonnées des points du cube 3D après une rotation sur l'axe Z
LOCAL X:REAL8, Y:REAL8, Z:REAL8		;X', Y', Z'

	
	mov eax, 0	;compteur dans objet[] pour la lecture
	mov ebx, 0	;compteur dans objet[] pour l'écriture
		
	RotationZ:
	
		fld objet[eax * REAL8]			; on récupère la coordonnée X du point
		fstp X
		inc eax
		
		fld objet[eax * REAL8]			; on récupère la coordonnée Y du point
		fstp Y
		inc eax
		
		fld objet[eax * REAL8]			; on récupère la coordonnée Z du point
		fstp Z
		inc eax
		
	
		;X
			fld Zrot 					; Zrot dans ST(0)
			fcos						; cos(Zrot) dans ST(0)
			fmul X  		    		; X * cos(Zrot) dans ST(0)
			fld	Zrot       				; Zrot dans ST(0)
			Fsin						; sin(Zrot) dans ST(0)
			fmul Y 						; Y * sin(Zrot) dans ST(0)
			fsubp ST(1), ST(0)			; X * cos(Zrot) -  Y* sin(Zrot) dans ST(0)
			fstp objet[ebx * REAL8]		; X' dans objet[]
			inc ebx

		;Y
			fld Zrot 					; Zrot dans ST(0)
			fsin 						; sin(Zrot) dans ST(0)
			fmul X  					; X * sin(Zrot) dans ST(0)
			fld Zrot 					; Zrot dans ST(0)
			fcos 						; cos(Zrot) dans ST(0)
			fmul Y 						; Y * cos(Zrot) dans ST(0)
			faddp ST(1), ST(0) 			; X * sin(Zrot) + Y * cos(Zrot) dans ST(0)
			fstp objet[ebx * REAL8]		; Y' dans objet[]
			inc ebx

		;Z
			inc ebx						; aucun changement, on passe à la case suivante
		
	
			cmp eax, 23
			jb RotationZ				; on réalise cette étape pour les 24 points du tableau objet[]
	
	
	
	ret

rotationZ endp
			
	testNormale proc counter:DWORD									; objectif de la fonction : tester si on doit afficher la face, renvoie 1 si oui dans eax
																	; prend en paramètre l'indice du premier point de la face dans faces[]
	LOCAL retour:DWORD, vecteur1X:REAL8, vecteur1Y:REAL8, vecteur2X:REAL8, vecteur2Y:REAL8, X1:REAL8, Y1:REAL8, X2:REAL8, Y2:REAL8, X3:REAL8, Y3:REAL8

	
	
	mov ecx, counter						; counter represente le premier point de la face à tester dans faces[]
	movzx eax, faces[ecx*BYTE]				; met dans eax le numéro du points dont nous allons récupérer ses coordonnées
	shl eax,1								; multiplie par 2 car chaque point possède 2 valeurs (x,y)
	
	fld points2D[eax*REAL8]					; on récupère la coordonnée X du premier point de la face
	fstp X1
	
	inc eax									; on souhaite récupérer la coordonnée Y (case suivante)
	
	fld points2D[eax*REAL8]					; on récupère Y du premier point de la face
	fstp Y1
	
	inc counter								; on souhaite récupérer les coordonnées du 2e points de la face à afficher dans faces[]
	
	mov ecx, counter
	movzx eax, faces[ecx*BYTE]				; même fonctionnement que pour la récupération des coordonnées X1-Y1
	shl eax,1
	
	fld points2D[eax*REAL8]
	fstp X2
	
	inc eax
	
	fld points2D[eax*REAL8]
	fstp Y2
	
	inc counter								; on souhaite récupérer les coordonnées du 3e points de la face à afficher dans faces[]
	
	mov ecx, counter						; même fonctionnement que pour la récupération des coordonnées X1-Y1
	movzx eax, faces[ecx*BYTE]
	shl eax,1
	
	fld points2D[eax*REAL8]
	fstp X3
	
	inc eax
	
	fld points2D[eax*REAL8]
	fstp Y3
												; le premier point de la face correspond à C, le deuxieme à B et le 3e à A
												; soit le premier vecteur BA puis le second Vecteur BC (ils reprentent les vecteurs des 3 premiers points de chaque faces)
												; Ils sont orienté dans le sens des aiguilles d'une montre
												

	;Calcul des coordonnées du vecteur BA:
		fld X3
		fsub X2				;X3 - X2
		fstp vecteur1X
	

		fld Y3
		fsub Y2				;Y3 - Y2
		fstp vecteur1Y
		

	;Calcul des coordonnées du vecteur BC:
		fld X1
		fsub X2				;X1 - X2
		fstp vecteur2X
				
		fld Y1
		fsub Y2				;Y1 - Y2
		fstp vecteur2Y
		

	
		
	;Calcul des vecteurs
	
		fld vecteur1X		
		fmul vecteur2Y			;(X3 - X2) * (Y1 - Y2)
		
		fld vecteur1Y
		fmul vecteur2X			; (Y3 - Y2) * (X1 - X2)
		
		
	
		fsubp ST(1), ST(0)		;  (X3 - X2)*(Y1 - Y2) - (Y3 - Y2)*(X1 - X2)

		fistp retour			; on récupère la valeur 

		cmp retour, 0
		jg positif
			
			mov edx, 0			; Si retour <= 0 la fonction retourne 0 dans edx
			
			jmp suite

		positif:

		mov edx, 1				; Si retour > 0 la fonction retourne 1 dans edx
		
		
		suite:
		
		
		ret
	


testNormale endp
	
	afficherFace proc counter:DWORD									; objectif de la fonction : dessiner une face
																	; prend en paramètre l'indice du premier point de la face dans faces[]
LOCAL X1:DWORD, Y1:DWORD, X2:DWORD, Y2:DWORD, counterPoint:BYTE

	mov counterPoint,0
		
	afficher:
	
		mov ecx, counter						; counter represente le premier point de la face à afficher dans faces[]
		movzx eax, faces[ecx*BYTE]				; met dans eax le numéro du points dont nous allons récupérer ses coordonnées
		shl eax,1								; multiplie par 2 car chaque point possède 2 valeurs (x,y)
	
		fld points2D[eax*REAL8]					; on récupère la coordonnée X du premier point de la face
		fistp X1
	
		inc eax									; on souhaite récupérer la coordonnée Y (case suivante)
	
		fld points2D[eax*REAL8]					; on récupère Y du premier point de la face
		fistp Y1
	
		inc counter								; on récupère les coordonnées du 2e point de la face
	
		mov ecx, counter
		movzx eax, faces[ecx*BYTE]
		shl eax,1
	
		fld points2D[eax*REAL8]					; meme fonctionnement
		fistp X2
	
		inc eax
	
		fld points2D[eax*REAL8]
		fistp Y2
	
		invoke MoveToEx,hdc,X1,Y1,NULL	; place la pointe de crayon aux coordonnées (X1,Y1)			
		invoke LineTo,hdc,X2,Y2			; trace une ligne de la position précédente à (X2,Y2)	
		
		
		inc counterPoint

		cmp counterPoint,4
		jb afficher
	ret

afficherFace endp
 
start: 

    invoke GetModuleHandle, NULL 
    mov    hInstance,eax 
    invoke GetCommandLine
    mov CommandLine,eax 
    invoke WinMain, hInstance,NULL,CommandLine, SW_SHOWDEFAULT 
    invoke ExitProcess,eax

WinMain proc hInst:HINSTANCE,hPrevInst:HINSTANCE,CmdLine:LPSTR,CmdShow:DWORD 
    LOCAL wc:WNDCLASSEX 
    LOCAL msg:MSG 
    LOCAL hwnd:HWND 
    
    mov   	wc.cbSize, SIZEOF WNDCLASSEX	; taille de la structure de la window class
	mov   	wc.style, CS_HREDRAW or CS_VREDRAW ; style de la fenêtre : redessinée si redim. ou mouv. horizontal ou vertical
	mov   	wc.lpfnWndProc, OFFSET WndProc	;pointeur vers la fonction de gestion de la fenêtre
	mov   	wc.cbClsExtra, NULL	; nombre de bits supplémentaires à allouer après la window class
	mov   	wc.cbWndExtra, NULL	; nombre de bits supplémentaires à allouer après l'instance de fenêtre
	push  	hInst 
    pop   	wc.hInstance ; un handle de l'instance qui contient la fonction de gestion de la fenêtre
	mov   	wc.hbrBackground, COLOR_WINDOW+1	; handle de la class backgroune brush utilisé pour le fond de la fenêtre
	mov   	wc.lpszMenuName, NULL	; pointeur vers une chaîne précisant le nom de la ressource menu name
	mov   	wc.lpszClassName, OFFSET ClassName ; pointeur vers le nom de la classe de la fenêtre
	
    invoke 	LoadIcon, NULL, IDI_APPLICATION ; arg1=handle vers le module contenant l'icone à charger, NULL pour une icone prédéfinie, arg2=nom del'icone à charger ou icone prédéfinie 
	
	mov   	wc.hIcon, eax	; un handle de la classe icon (vers une ressource de type icon)
	mov   	wc.hIconSm, eax	; un handle de la classe small icon (vers une ressource de type icon)
	
	invoke 	LoadCursor, NULL, IDC_ARROW	; arg1=handle vers le module contenant le curseur à charger, NULL pour un curseur prédéfini, arg2=nom du curseur à charger ou curseur prédéfini
	
	mov   	wc.hCursor, eax	; un handle de la classe cursor (vers une ressource de type cursor)
	
	invoke 	RegisterClassEx, addr wc	; enregistre la window class définie au-dessus

    invoke CreateWindowEx,WS_EX_CLIENTEDGE,ADDR ClassName, \ 
                        ADDR AppName, WS_OVERLAPPEDWINDOW + WS_HSCROLL + WS_VSCROLL,\ 
                        CW_USEDEFAULT, CW_USEDEFAULT,\ 
                        largeur,hauteur,NULL,NULL, hInst,NULL 
    
    mov   	hwnd, eax	; eax=valeur de retour de CreateWindowEx, copiée dans hwnd 
    
	invoke 	ShowWindow, hwnd, SW_SHOWNORMAL ; handle de la fenêtre
											; mode d'affichage de la fenêtre
    
    messages:
        invoke GetMessage, ADDR msg,NULL,0,0 
        cmp eax,0
        jle fin_boucle 
        invoke TranslateMessage, ADDR msg 
        invoke DispatchMessage, ADDR msg 
    jmp messages
    fin_boucle:
    mov     eax,msg.wParam 
    ret 
WinMain endp

WndProc proc hWnd:HWND, uMsg:UINT, wParam:WPARAM, lParam:LPARAM 
    
    cmp uMsg,WM_DESTROY	; demande de fermeture de la fenêtre (clic sur croix rouge)
    je destroy
    cmp uMsg,WM_PAINT	; message WM_PAINT envoyé à chaque rafraîchissement de la fenêtre
    je paint
    invoke DefWindowProc,hWnd,uMsg,wParam,lParam ; si aucun des messages précédents
    ret 
    
    destroy:
    	invoke PostQuitMessage,NULL
    	
    jmp fin_messages 

    paint:
    		
    		
			Invoke DegVersRadian		
    		Invoke rotationX
			Invoke rotationY
			Invoke rotationZ
		
			Invoke calculProjection
		
			invoke BeginPaint, hWnd, ADDR ps			; lance le dessin de la fenêtre
			mov hdc, eax								; BeginPaint retourne le handle du contexte où on dessine
			
			boucleParcoursTableau:
		
				Invoke testNormale, counterFace			; teste si on affiche la face
		
				cmp edx, 0
				jle pasAfficher							; si la fonction (qui stocke le résultat dans edx = 1) on lance la fonction qui affiche
					
					Invoke afficherFace, counterFace
							
				pasAfficher:				
				
		
				add counterFace, 5						; on passe à la face suivante
		
			cmp counterFace, 26							; on boucle jusqu'a au moins 26 pour afficher toutes les faces
			jb boucleParcoursTableau			
    	   	
				
        	invoke EndPaint, hWnd, ADDR ps 				; fin du dessin de la fenêtre
        	
        
    fin_messages:
    xor    eax,eax 
    ret 
WndProc endp 
push 0
call ExitProcess      	
end start