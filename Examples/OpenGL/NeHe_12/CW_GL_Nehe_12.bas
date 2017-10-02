' ########################################################################################
' Microsoft Windows
' File: CW_OGL_Nehe_12
' Contents: CWindow OpenGL - NeHe lesson 12
' Compiler: FreeBasic 32 & 64 bit
' Translated in 2017 by Jos� Roca. Freeware. Use at your own risk.
' THIS CODE AND INFORMATION IS PROVIDED "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER
' EXPRESSED OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE IMPLIED WARRANTIES OF
' MERCHANTABILITY AND/OR FITNESS FOR A PARTICULAR PURPOSE.
' ########################################################################################

' Press ESC key to quit
' Use arrow keys to rotate cubes

#define UNICODE
#INCLUDE ONCE "Afx/CWindow.inc"
#INCLUDE ONCE "GL/windows/glu.bi"
#INCLUDE ONCE "Afx/AfxGdiplus.inc"
USING Afx

CONST GL_WINDOWWIDTH   = 600               ' Window width
CONST GL_WINDOWHEIGHT  = 400               ' Window height
CONST GL_WindowCaption = "NeHe Lesson 12"  ' Window caption

DECLARE FUNCTION WinMain (BYVAL hInstance AS HINSTANCE, _
                          BYVAL hPrevInstance AS HINSTANCE, _
                          BYVAL szCmdLine AS ZSTRING PTR, _
                          BYVAL nCmdShow AS LONG) AS LONG

   END WinMain(GetModuleHandleW(NULL), NULL, COMMAND(), SW_NORMAL)

' // Forward declarations
DECLARE FUNCTION WndProc (BYVAL hwnd AS HWND, BYVAL uMsg AS UINT, BYVAL wParam AS WPARAM, BYVAL lParam AS LPARAM) AS LRESULT

' =======================================================================================
' OpenGL class
' =======================================================================================
TYPE COGL

   Private:
      m_hDC AS HDC        ' // Device context handle
      m_hRC AS HGLRC      ' // Rendering context handle
      m_hwnd AS HWND      ' // Window handle

      TextureHandle AS GLuint
      box AS DWORD
      top AS DWORD
      xrot AS SINGLE
      yrot AS SINGLE

      ' // Array for box colors
      DIM boxcol(4, 2) AS SINGLE = { _
         {1.0, 0.0, 0.0}, _     ' Bright: Red,
         {1.0, 0.5, 0.0}, _     ' Bright: Orange,
         {1.0, 1.0, 0.0}, _     ' Bright: Yellow,
         {0.0 ,1.0, 0.0}, _     ' Bright: Green,
         {0.0, 1.0, 1.0}}       ' Bright: Blue
      ' // Array for top colors
      DIM topcol(4, 2) AS SINGLE = { _
         { .5, 0.0, 0.0}, _     ' Dark: Red,
         {0.5, 0.25,0.0}, _     ' Dark: Orange,
         {0.5, 0.5, 0.0}, _     ' Dark: Yellow,
         {0.0, 0.5, 0.0}, _     ' Dark: Green,
         {0.0, 0.5, 0.5}}       ' Dark: Blue

   Public:
      DECLARE CONSTRUCTOR (BYVAL hwnd AS HWND, BYVAL nBitsPerPel AS LONG = 32, BYVAL cDepthBits AS LONG = 24)
      DECLARE DESTRUCTOR
      DECLARE SUB SetupScene (BYVAL nWidth AS LONG, BYVAL nHeight AS LONG)
      DECLARE SUB ResizeScene (BYVAL nWidth AS LONG, BYVAL nHeight AS LONG)
      DECLARE SUB RenderScene
      DECLARE SUB ProcessKeystrokes (BYVAL uMsg AS UINT, BYVAL wParam AS WPARAM, BYVAL lParam AS LPARAM)
      DECLARE SUB ProcessMouse (BYVAL uMsg AS UINT, BYVAL wKeyState AS DWORD, BYVAL x AS LONG, BYVAL y AS LONG)
      DECLARE SUB Cleanup

END TYPE
' =======================================================================================

' ========================================================================================
' COGL constructor
' ========================================================================================
CONSTRUCTOR COGL (BYVAL hwnd AS HWND, BYVAL nBitsPerPel AS LONG = 32, BYVAL cDepthBits AS LONG = 24)

   DO   ' // Using a fake loop to avoid the use of GOTO or nested IFs/END IFs

      ' // Get the device context
      IF hwnd = NULL THEN EXIT DO
      m_hwnd = hwnd

      ' // Get the device context of the window
      m_hDC = GetDC(m_hwnd)
      IF m_hDC = NULL THEN EXIT DO

      ' // Pixel format
      DIM pfd AS PIXELFORMATDESCRIPTOR
      pfd.nSize      = SIZEOF(PIXELFORMATDESCRIPTOR)
      pfd.nVersion   = 1
      pfd.dwFlags    = PFD_DRAW_TO_WINDOW OR PFD_SUPPORT_OPENGL OR PFD_DOUBLEBUFFER
      pfd.iPixelType = PFD_TYPE_RGBA
      pfd.cColorBits = nBitsPerPel
      pfd.cDepthBits = cDepthBits

      ' // Find a matching pixel format
      DIM pf AS LONG = ChoosePixelFormat(m_hDC, @pfd)
      IF pf = 0 THEN
         MessageBoxW hwnd, "Can't find a suitable pixel format", _
                     "Error", MB_OK OR MB_ICONEXCLAMATION
         EXIT DO
      END IF

      ' // Set the pixel format
      IF SetPixelFormat(m_hDC, pf, @pfd) = FALSE THEN
         MessageBoxW hwnd, "Can't set the pixel format", _
                     "Error", MB_OK OR MB_ICONEXCLAMATION
         EXIT DO
      END IF

      ' // Create a new OpenGL rendering context
      m_hRC = wglCreateContext(m_hDC)
      IF m_hRC = NULL THEN
         MessageBoxW hwnd, "Can't create an OpenGL rendering context", _
                     "Error", MB_OK OR MB_ICONEXCLAMATION
         EXIT DO
      END IF

      ' // Make it current
      IF wglMakeCurrent(m_hDC, m_hRC) = FALSE THEN
         MessageBoxW hwnd, "Can't activate the OpenGL rendering context", _
                     "Error", MB_OK OR MB_ICONEXCLAMATION
         EXIT DO
      END IF

      ' // Exit the fake loop
      EXIT DO
   LOOP

END CONSTRUCTOR
' ========================================================================================

' ========================================================================================
' COGL Destructor
' ========================================================================================
DESTRUCTOR COGL
   ' // Release the device and rendering contexts
   wglMakeCurrent m_hDC, NULL
   ' // Make the rendering context no longer current
   wglDeleteContext m_hRC
   ' // Release the device context
   ReleaseDC m_hwnd, m_hDC
END DESTRUCTOR
' ========================================================================================

' =======================================================================================
' All the setup goes here
' =======================================================================================
SUB COGL.SetupScene (BYVAL nWidth AS LONG, BYVAL nHeight AS LONG)

   ' // Load bitmap texture from disk
   DIM strTextureData AS STRING, TextureWidth AS LONG, TextureHeight AS LONG
   DIM hr AS LONG = AfxGdipLoadTexture("cube.bmp", TextureWidth, TextureHeight, strTextureData)
   ' Assign an OpenGL handle to this texture
   glGenTextures 1, @TextureHandle

   ' // Create the texture
   glBindTexture GL_TEXTURE_2D, TextureHandle
   glTexParameteri GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR
   glTexParameteri GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR
   glTexImage2D GL_TEXTURE_2D, 0, 3, TextureWidth, TextureHeight, 0, _
                GL_RGBA, GL_UNSIGNED_BYTE, BYVAL STRPTR(strTextureData)

   ' // Build lists
   box = glGenLists(2)                ' generate 2 different lists
   glNewList box, GL_COMPILE         ' Start with the box list
      glBegin GL_QUADS
         ' Bottom Face
         glNormal3f   0.0,-1.0, 0.0
         glTexCoord2f 1.0, 1.0 : glVertex3f -1.0, -1.0, -1.0
         glTexCoord2f 0.0, 1.0 : glVertex3f  1.0, -1.0, -1.0
         glTexCoord2f 0.0, 0.0 : glVertex3f  1.0, -1.0,  1.0
         glTexCoord2f 1.0, 0.0 : glVertex3f -1.0, -1.0,  1.0
         ' Front Face
         glNormal3f   0.0, 0.0, 1.0
         glTexCoord2f 0.0, 0.0 : glVertex3f -1.0, -1.0,  1.0
         glTexCoord2f 1.0, 0.0 : glVertex3f  1.0, -1.0,  1.0
         glTexCoord2f 1.0, 1.0 : glVertex3f  1.0,  1.0,  1.0
         glTexCoord2f 0.0, 1.0 : glVertex3f -1.0,  1.0,  1.0
         ' Back Face
         glNormal3f   0.0, 0.0, -1.0
         glTexCoord2f 1.0, 0.0 : glVertex3f -1.0, -1.0, -1.0
         glTexCoord2f 1.0, 1.0 : glVertex3f -1.0,  1.0, -1.0
         glTexCoord2f 0.0, 1.0 : glVertex3f  1.0,  1.0, -1.0
         glTexCoord2f 0.0, 0.0 : glVertex3f  1.0, -1.0, -1.0
         ' Right face
         glNormal3f   1.0, 0.0, 0.0
         glTexCoord2f 1.0, 0.0 : glVertex3f  1.0, -1.0, -1.0
         glTexCoord2f 1.0, 1.0 : glVertex3f  1.0,  1.0, -1.0
         glTexCoord2f 0.0, 1.0 : glVertex3f  1.0,  1.0,  1.0
         glTexCoord2f 0.0, 0.0 : glVertex3f  1.0, -1.0,  1.0
         ' Left Face
         glNormal3f  -1.0, 0.0, 0.0
         glTexCoord2f 0.0, 0.0 : glVertex3f -1.0, -1.0, -1.0
         glTexCoord2f 1.0, 0.0 : glVertex3f -1.0, -1.0,  1.0
         glTexCoord2f 1.0, 1.0 : glVertex3f -1.0,  1.0,  1.0
         glTexCoord2f 0.0, 1.0 : glVertex3f -1.0,  1.0, -1.0
      glEnd
   glEndList
   top = box + 1                      ' Storage for "Top" is "Box" plus one
   glNewList top, GL_COMPILE         ' Now the "Top" display list
      glBegin GL_QUADS
         ' Top Face
         glNormal3f   0.0, 1.0, 0.0
         glTexCoord2f 0.0, 1.0 : glVertex3f -1.0,  1.0, -1.0
         glTexCoord2f 0.0, 0.0 : glVertex3f -1.0,  1.0,  1.0
         glTexCoord2f 1.0, 0.0 : glVertex3f  1.0,  1.0,  1.0
         glTexCoord2f 1.0, 1.0 : glVertex3f  1.0,  1.0, -1.0
      glEnd
   glEndList

   ' // Enable texture mapping
   glEnable GL_TEXTURE_2D

   ' // Specify clear values for the color buffers
   glClearColor 0.0, 0.0, 0.0, 0.0
   ' // Specify the clear value for the depth buffer
   glClearDepth 1.0
   ' // Specify the value used for depth-buffer comparisons
   glDepthFunc GL_EQUAL
   ' // Select smooth shading
   glShadeModel GL_SMOOTH
   '  // Quick and dirty lighting (assumes Light0 is set up)
   glEnable GL_LIGHT0
	'  // Enable lighting
'   glEnable %GL_LIGHTING
	' // Enable material coloring
   glEnable GL_COLOR_MATERIAL
	' // Really nice perspective calculations
   glHint GL_PERSPECTIVE_CORRECTION_HINT, GL_NICEST

END SUB
' =======================================================================================

' =======================================================================================
' Resize the scene
' =======================================================================================
SUB COGL.ResizeScene (BYVAL nWidth AS LONG, BYVAL nHeight AS LONG)

   ' // Prevent divide by zero making height equal one
   IF nHeight = 0 THEN nHeight = 1
   ' // Reset the current viewport
   glViewport 0, 0, nWidth, nHeight
   ' // Select the projection matrix
   glMatrixMode GL_PROJECTION
   ' // Reset the projection matrix
   glLoadIdentity
   ' // Calculate the aspect ratio of the window
   gluPerspective 45.0, nWidth / nHeight, 0.1, 100.0
   ' // Select the model view matrix
   glMatrixMode GL_MODELVIEW
   ' // Reset the model view matrix
   glLoadIdentity

END SUB
' =======================================================================================

' =======================================================================================
' Draw the scene
' =======================================================================================
SUB COGL.RenderScene

   ' // Clear the screen buffer
   glClear GL_COLOR_BUFFER_BIT OR GL_DEPTH_BUFFER_BIT
   ' // Reset the view
   glLoadIdentity

   glBindTexture GL_TEXTURE_2D, TextureHandle
   FOR yloop AS LONG = 1 TO 5
      FOR xloop AS LONG = 0 TO yloop - 1
         glLoadIdentity   ' Reset the view
         glTranslatef 1.4 + (xloop * 2.8) - (yloop * 1.4), ((6.0 - yloop) * 2.4) - 7.0, -20.0
         glRotatef 45.0 - (2.0 * yloop) + xrot, 1.0, 0.0, 0.0
         glRotatef 45.0 + yrot, 0.0, 1.0, 0.0
         glColor3fv @boxcol(yloop - 1, 0)
         glCallList box
         glColor3fv @topcol(yloop - 1, 0)
         glCallList top
      NEXT
   NEXT

   ' // Exchange the front and back buffers
   SwapBuffers m_hdc

END SUB
' =======================================================================================

' =======================================================================================
' Processes keystrokes
' Parameters:
' * uMsg = The Windows message
' * wParam = Additional message information.
' * lParam = Additional message information.
' The contents of the wParam and lParam parameters depend on the value of the uMsg parameter.
' =======================================================================================
SUB COGL.ProcessKeystrokes (BYVAL uMsg AS UINT, BYVAL wParam AS WPARAM, BYVAL lParam AS LPARAM)

   STATIC AS BOOLEAN lp, fp, light

   SELECT CASE uMsg
      CASE WM_KEYDOWN   ' // A nonsystem key has been pressed
         SELECT CASE LOWORD(wParam)
            CASE VK_ESCAPE
               ' // Send a message to close the application
               SendMessageW m_hwnd, WM_CLOSE, 0, 0
            CASE VK_LEFT
               yrot -= 0.2
            CASE VK_RIGHT
               yrot += 0.2
            CASE VK_UP
               xrot -= 0.2
            CASE VK_DOWN
               xrot += 0.2
         END SELECT
   END SELECT

END SUB
' =======================================================================================

' =======================================================================================
' Processes mouse clicks and movement
' Parameters:
' * wMsg      = Windows message
' * wKeyState = Indicates whether various virtual keys are down.
'               MK_CONTROL    The CTRL key is down.
'               MK_LBUTTON    The left mouse button is down.
'               MK_MBUTTON    The middle mouse button is down.
'               MK_RBUTTON    The right mouse button is down.
'               MK_SHIFT      The SHIFT key is down.
'               MK_XBUTTON1   Windows 2000/XP: The first X button is down.
'               MK_XBUTTON2   Windows 2000/XP: The second X button is down.
' * x         = x-coordinate of the cursor
' * y         = y-coordinate of the cursor
' =======================================================================================
SUB COGL.ProcessMouse (BYVAL uMsg AS UINT, BYVAL wKeyState AS DWORD, BYVAL x AS LONG, BYVAL y AS LONG)

   SELECT CASE uMsg

      CASE WM_LBUTTONDOWN   ' // Left mouse button pressed
         ' // Put your code here

      CASE WM_LBUTTONUP   ' // Left mouse button releases
         ' // Put your code here

      CASE WM_MOUSEMOVE   ' // Mouse has been moved
         ' // Put your code here

      END SELECT

END SUB
' =======================================================================================

' =======================================================================================
' Cleanup
' =======================================================================================
SUB COGL.Cleanup

   ' // Delete the texture
   IF TextureHandle THEN glDeleteTextures(1, @TextureHandle)
   ' // Delete the lists
   glDeleteLists box, 2

END SUB
' =======================================================================================

' ========================================================================================
' Main
' ========================================================================================
FUNCTION WinMain (BYVAL hInstance AS HINSTANCE, _
                  BYVAL hPrevInstance AS HINSTANCE, _
                  BYVAL szCmdLine AS ZSTRING PTR, _
                  BYVAL nCmdShow AS LONG) AS LONG

   ' // Set process DPI aware
   ' // The recommended way is to use a manifest file
   AfxSetProcessDPIAware

   ' // Creates the main window
   DIM pWindow AS CWindow
   ' -or- DIM pWindow AS CWindow = "MyClassName" (use the name that you wish)
   ' // Create the window
   DIM hwndMain AS HWND = pWindow.Create(NULL, GL_WindowCaption, @WndProc)
   ' // Don't erase the background
   pWindow.ClassStyle = CS_DBLCLKS
   ' // Use a black brush
   pWindow.Brush = CreateSolidBrush(BGR(0, 0, 0))
   ' // Sizes the window by setting the wanted width and height of its client area
   pWindow.SetClientSize(GL_WINDOWWIDTH, GL_WINDOWHEIGHT)
   ' // Centers the window
   pWindow.Center

   ' // Show the window
   ShowWindow hwndMain, nCmdShow
   UpdateWindow hwndMain
 
   ' // Message loop
   DIM uMsg AS tagMsg
   WHILE GetMessageW(@uMsg, NULL, 0, 0)
      TranslateMessage @uMsg
      DispatchMessageW @uMsg
   WEND

   FUNCTION = uMsg.wParam

END FUNCTION
' ========================================================================================

' ========================================================================================
' Main window procedure
' ========================================================================================
FUNCTION WndProc (BYVAL hwnd AS HWND, BYVAL uMsg AS UINT, BYVAL wParam AS WPARAM, BYVAL lParam AS LPARAM) AS LRESULT

   STATIC pCOGL AS COGL PTR   ' // Pointer to the COGL class

   SELECT CASE uMsg

      CASE WM_SYSCOMMAND
         ' // Disable the Windows screensaver
         IF (wParam AND &hFFF0) = SC_SCREENSAVE THEN EXIT FUNCTION
         ' // Close the window
         IF (wParam AND &hFFF0) = SC_CLOSE THEN
            SendMessageW hwnd, WM_CLOSE, 0, 0
            EXIT FUNCTION
         END IF

      CASE WM_CREATE
         ' // Initialize the new OpenGL window
         pCOGL = NEW COGL(hwnd)
         ' // Retrieve the coordinates of the window's client area
         DIM rc AS RECT
         GetClientRect hwnd, @rc
         ' // Set up the scene
         pCOGL->SetupScene rc.Right - rc.Left, rc.Bottom - rc.Top
         ' // Set the timer (using a timer to trigger redrawing allows a smoother rendering)
         SetTimer(hwnd, 1, 0, NULL)
         EXIT FUNCTION

    	CASE WM_DESTROY
         ' // Kill the timer
         KillTimer(hwnd, 1)
         ' // Clean resources
         pCOGL->Cleanup
         ' // Delete the COGL class
         Delete pCOGL
         ' // Ends the application by sending a WM_QUIT message
         PostQuitMessage(0)
         EXIT FUNCTION

      CASE WM_TIMER
         ' // Render the scene
         pCOGL->RenderScene
         EXIT FUNCTION

      CASE WM_SIZE
         pCOGL->ResizeScene LOWORD(lParam), HIWORD(lParam)
         EXIT FUNCTION

      CASE WM_KEYDOWN
         ' // Process keystrokes
         pCOGL->ProcessKeystrokes uMsg, wParam, lParam
         EXIT FUNCTION

      CASE WM_LBUTTONDOWN, WM_LBUTTONUP, WM_MOUSEMOVE
         ' // Process mouse movements
         pCOGL->ProcessMouse uMsg, wParam, LOWORD(lParam), HIWORD(lParam)
         EXIT FUNCTION

   END SELECT

   ' // Default processing of Windows messages
   FUNCTION = DefWindowProcW(hwnd, uMsg, wParam, lParam)

END FUNCTION
' ========================================================================================
