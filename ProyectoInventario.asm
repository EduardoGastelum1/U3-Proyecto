INCLUDE Irvine32.inc

; LÍMITES DE DATOS Y CONSTANTES

MAX_PRODUCTOS   EQU 10
TAM_CODIGO      EQU 8   ; 3 letras, '-', 3 dígitos + 0h
TAM_NOMBRE      EQU 26  ; 25 caracteres + 0h
TAM_REGISTRO    EQU 42  ; 8 (código) + 26 (nombre) + 4 (precio) + 4 (existencia)

; MACROS (UNIDAD 3)

; Macro para imprimir cadenas de texto y dar salto de línea automático
ImprimirTexto MACRO mensaje
    push edx
    mov edx, OFFSET mensaje
    call WriteString
    call Crlf
    pop edx
ENDM

; Macro para limpiar el búfer de entrada de manera automatizada usando LOCAL
LimpiarBuffer MACRO
    LOCAL limpiar_loop
    push ecx
    push esi
    mov ecx, SIZEOF bufferEntrada
    mov esi, OFFSET bufferEntrada
    mov al, 0
limpiar_loop:
    mov [esi], al
    inc esi
    loop limpiar_loop
    pop esi
    pop ecx
ENDM

; Macro para estandarizar la salida de errores con salto de línea
MostrarError MACRO mensajeErrorTxt
    call Crlf
    ImprimirTexto mensajeErrorTxt
    call Crlf
ENDM


.data
    mensajeTitulo         BYTE "=== SISTEMA DE VENTAS E INVENTARIO PAPELERIA===", 0
    mensajeOpc1           BYTE "1. Registrar producto", 0
    mensajeOpc2           BYTE "2. Buscar producto", 0
    mensajeOpc3           BYTE "3. Recibir mercancia", 0
    mensajeOpc4           BYTE "4. Vender producto (Mayoreo 10+)", 0
    mensajeOpc5           BYTE "5. Mostrar resumen", 0
    mensajeOpc6           BYTE "6. Guardar inventario en archivo", 0
    mensajeOpc7           BYTE "7. Cargar inventario de archivo", 0
    mensajeOpc8           BYTE "8. Salir", 0
    mensajeSeleccion      BYTE "Seleccione una opcion: ", 0
    
    mensajeError          BYTE "Opcion invalida.", 0
    mensajeLleno          BYTE "Inventario lleno (Maximo 10 productos).", 0
    mensajeExitoReg       BYTE "Producto registrado exitosamente.", 0
    mensajeErrCodigo      BYTE "Error: El codigo debe tener formato ABC-123 (3 letras, guion, 3 digitos).", 0
    mensajeDuplicado      BYTE "Error: El codigo ya existe en el catalogo.", 0
    
    mensajePedirCod       BYTE "Ingrese codigo (ej. LAP-001): ", 0
    mensajePedirNom       BYTE "Ingrese nombre del producto: ", 0
    mensajePedirPre       BYTE "Ingrese precio en pesos (ej. 185.50): ", 0
    mensajePedirExt       BYTE "Ingrese existencias (0 a 100): ", 0
    mensajeErrNum         BYTE "Error: Entrada numerica invalida o fuera de rango.", 0
    
    mensajeNoEncontrado   BYTE "Producto no encontrado en el inventario.", 0
    mensajeEncontrado     BYTE "--- PRODUCTO ENCONTRADO ---", 0
    mensajeTxtCod         BYTE "Codigo: ", 0
    mensajeTxtNom         BYTE "Nombre: ", 0
    mensajeTxtPre         BYTE "Precio: ", 0
    mensajeTxtExt         BYTE "Existencias: ", 0
    
    mensajePedirCantEnt   BYTE "Ingrese unidades a recibir: ", 0
    mensajeExitoEnt       BYTE "Mercancia recibida exitosamente.", 0
    mensajeErrMaxExt      BYTE "Error: Las existencias totales no pueden superar 100.", 0

    mensajePedirCantVenta BYTE "Ingrese cantidad a vender: ", 0
    mensajeSinExistencias BYTE "Error: Stock insuficiente o producto sin existencias.", 0
    mensajeVentaExito     BYTE "Venta exitosa! Total pagado: ", 0

    mensajeResumen1       BYTE "--- RESUMEN DE LA SESION ---", 0
    mensajeResumenProd    BYTE "Total de productos en catalogo: ", 0
    mensajeResumenVal     BYTE "Valor total del inventario: ", 0
    mensajeResumenIng     BYTE "Ingresos totales de la sesion: ", 0
    etiquetaMXN           BYTE " MXN", 0

    mensajeGuardarExito   BYTE "Catalogo guardado exitosamente en disco.", 0
    mensajeCargarExito    BYTE "Catalogo cargado exitosamente desde disco.", 0
    mensajeErrorArchivo   BYTE "Error al abrir, leer o escribir en el archivo.", 0

    ; Almacenamiento en memoria ordenado para persistencia
    total_productos       DWORD 0
    ingresos_sesion       DWORD 0    
    catalogo              BYTE TAM_REGISTRO * MAX_PRODUCTOS DUP(0)
    
    bufferEntrada         BYTE 40 DUP(0)
    aux_precio            DWORD 0
    aux_existencia        DWORD 0
    nombreArchivo         BYTE "inventario.dat", 0
    fileHandle            DWORD 0

.code
main PROC
menu_principal:
    call Crlf
    ImprimirTexto mensajeTitulo
    ImprimirTexto mensajeOpc1
    ImprimirTexto mensajeOpc2
    ImprimirTexto mensajeOpc3
    ImprimirTexto mensajeOpc4
    ImprimirTexto mensajeOpc5
    ImprimirTexto mensajeOpc6
    ImprimirTexto mensajeOpc7
    ImprimirTexto mensajeOpc8
    
    mov edx, OFFSET mensajeSeleccion
    call WriteString
    
    LimpiarBuffer
    mov edx, OFFSET bufferEntrada
    mov ecx, SIZEOF bufferEntrada
    call ReadString
    
    mov al, [bufferEntrada]
    cmp al, '1'
    je op_registrar
    cmp al, '2'
    je op_buscar
    cmp al, '3'
    je op_recibir
    cmp al, '4'
    je op_vender
    cmp al, '5'
    je op_resumen
    cmp al, '6'
    je op_guardar
    cmp al, '7'
    je op_cargar
    cmp al, '8'
    je fin
    
    MostrarError mensajeError
    jmp menu_principal

op_registrar:
    call Crlf
    call RegistrarProducto
    jmp menu_principal

op_buscar:
    call Crlf
    call BuscarProductoUI
    jmp menu_principal

op_recibir:
    call Crlf
    call RecibirMercancia
    jmp menu_principal

op_vender:
    call Crlf
    call VenderProducto
    jmp menu_principal

op_resumen:
    call Crlf
    call MostrarResumen
    jmp menu_principal

op_guardar:
    call Crlf
    call GuardarArchivo
    jmp menu_principal

op_cargar:
    call Crlf
    call CargarArchivo
    jmp menu_principal

fin:
    exit
main ENDP

; PROCEDIMIENTOS  CON USES (UNIDAD 3)

ValidarCodigo PROC USES esi
    mov esi, OFFSET bufferEntrada

    mov al, [esi]
    cmp al, 'A'
    jl invalido
    cmp al, 'Z'
    jg invalido

    mov al, [esi+1]
    cmp al, 'A'
    jl invalido
    cmp al, 'Z'
    jg invalido

    mov al, [esi+2]
    cmp al, 'A'
    jl invalido
    cmp al, 'Z'
    jg invalido

    mov al, [esi+3]
    cmp al, '-'
    jne invalido

    mov al, [esi+4]
    cmp al, '0'
    jl invalido
    cmp al, '9'
    jg invalido

    mov al, [esi+5]
    cmp al, '0'
    jl invalido
    cmp al, '9'
    jg invalido

    mov al, [esi+6]
    cmp al, '0'
    jl invalido
    cmp al, '9'
    jg invalido

    xor eax, eax  ; EAX fuera de USES para retornar éxito (0)
    ret

invalido:
    mov eax, 1    ; EAX fuera de USES para retornar error (1)
    ret
ValidarCodigo ENDP

CadenaAPrecioCentavos PROC USES esi ebx ecx edx
    mov esi, OFFSET bufferEntrada
    xor eax, eax        
    xor ecx, ecx        
    xor ebx, ebx        

recorrer_precio:
    movzx edx, byte ptr [esi]
    cmp dl, 0
    je fin_precio_str
    
    cmp dl, '.'
    je encontro_punto

    cmp dl, '0'
    jl error_conv_p
    cmp dl, '9'
    jg error_conv_p

    sub dl, 30h         
    push edx
    mov edx, 10
    mul edx             
    pop edx
    add eax, edx
    
    cmp eax, 999999     
    jg error_conv_p

    inc esi
    cmp ecx, -1
    je contar_decimales
    jmp recorrer_precio

contar_decimales:
    inc ebx
    cmp ebx, 2
    jg error_conv_p     
    jmp recorrer_precio

encontro_punto:
    cmp ecx, -1         
    je error_conv_p
    mov ecx, -1         
    xor ebx, ebx        
    inc esi
    jmp recorrer_precio

fin_precio_str:
    cmp ecx, -1
    jne multiplicar_cien  

    cmp ebx, 0
    je sin_digitos_dec
    cmp ebx, 1
    je un_decimal

    ret

multiplicar_cien:
    mov edx, 100
    mul edx
    ret

un_decimal:
    mov edx, 10
    mul edx
    ret

sin_digitos_dec:
    mov edx, 100
    mul edx
    ret

error_conv_p:
    mov eax, -1
    ret
CadenaAPrecioCentavos ENDP

CadenaAEntero PROC USES esi ebx edx
    mov esi, OFFSET bufferEntrada
    xor eax, eax
    xor ebx, ebx

    movzx edx, byte ptr [esi]
    cmp dl, 0
    je err_ent

recorrer_ent:
    movzx edx, byte ptr [esi]
    cmp dl, 0
    je fin_ent

    cmp dl, '0'
    jl err_ent
    cmp dl, '9'
    jg err_ent

    sub dl, 30h
    push edx
    mov edx, 10
    mul edx
    pop edx
    add eax, edx

    cmp eax, 1000       
    jg err_ent

    inc esi
    jmp recorrer_ent

fin_ent:
    ret

err_ent:
    mov eax, -1
    ret
CadenaAEntero ENDP

MostrarEnteroPropio PROC USES eax ebx ecx edx
    mov ecx, 0          
    mov ebx, 10

    cmp eax, 0
    jne convertir_loop
    mov al, '0'
    call WriteChar
    jmp fin_mostrar_ent

convertir_loop:
    cmp eax, 0
    je imprimir_apila
    xor edx, edx
    div ebx             
    add dl, 30h
    push edx
    inc ecx
    jmp convertir_loop

imprimir_apila:
    cmp ecx, 0
    je fin_mostrar_ent
    pop eax
    call WriteChar
    dec ecx
    jmp imprimir_apila

fin_mostrar_ent:
    ret
MostrarEnteroPropio ENDP

MostrarImporteMXN PROC USES eax ebx edx
    xor edx, edx
    mov ebx, 100
    div ebx             

    push edx            
    push eax            

    pop eax
    call MostrarEnteroPropio

    mov al, '.'
    call WriteChar

    pop edx
    cmp edx, 10
    jge centavos_normales
    push edx
    mov al, '0'
    call WriteChar
    pop edx

centavos_normales:
    mov eax, edx
    call MostrarEnteroPropio

    mov edx, OFFSET etiquetaMXN
    call WriteString

    ret
MostrarImporteMXN ENDP


; Búsqueda interna utilizando ESI

BuscarProductoInterno PROC USES ebx ecx edi
    mov esi, OFFSET catalogo
    xor ecx, ecx

ciclo_busqueda:
    cmp ecx, [total_productos]
    jge no_hallado

    push esi
    mov edi, OFFSET bufferEntrada
    mov ebx, 8
compara_bytes:
    mov al, [esi]
    mov ah, [edi]
    cmp al, ah
    jne no_es_este
    inc esi
    inc edi
    dec ebx
    jnz compara_bytes

    pop esi
    mov eax, 0 
    ret

no_es_este:
    pop esi
    add esi, TAM_REGISTRO
    inc ecx
    jmp ciclo_busqueda

no_hallado:
    mov eax, -1 
    ret
BuscarProductoInterno ENDP


; Registrar Producto

RegistrarProducto PROC USES ebp esi ebx ecx edi
    mov ebp, esp

    mov eax, [total_productos]
    cmp eax, MAX_PRODUCTOS
    jge error_limite

    mov edx, OFFSET mensajePedirCod
    call WriteString
    LimpiarBuffer
    mov edx, OFFSET bufferEntrada
    mov ecx, TAM_CODIGO
    call ReadString

    call ValidarCodigo
    jnz error_codigo_formato

    call BuscarProductoInterno
    cmp eax, 0
    je error_codigo_duplicado

    mov esi, OFFSET catalogo
    mov eax, [total_productos]
    mov ebx, TAM_REGISTRO
    mul ebx
    add esi, eax

    push esi
    mov edi, esi
    mov esi, OFFSET bufferEntrada
    mov ecx, TAM_CODIGO
    rep movsb
    pop esi

    mov edx, OFFSET mensajePedirNom
    call WriteString
    LimpiarBuffer
    mov edx, OFFSET bufferEntrada
    mov ecx, TAM_NOMBRE
    call ReadString
    
    push esi
    lea edi, [esi + TAM_CODIGO]
    mov esi, OFFSET bufferEntrada
    mov ecx, TAM_NOMBRE
    rep movsb
    pop esi

pedir_precio_loop:
    mov edx, OFFSET mensajePedirPre
    call WriteString
    LimpiarBuffer
    mov edx, OFFSET bufferEntrada
    mov ecx, 20
    call ReadString

    call CadenaAPrecioCentavos
    cmp eax, -1
    je err_precio_ingresado
    
    cmp eax, 0
    jle err_precio_ingresado
    cmp eax, 999999
    jg err_precio_ingresado

    mov [esi + 34], eax
    jmp continuar_existencias

err_precio_ingresado:
    MostrarError mensajeErrNum
    jmp pedir_precio_loop

continuar_existencias:
pedir_ext_loop:
    mov edx, OFFSET mensajePedirExt
    call WriteString
    LimpiarBuffer
    mov edx, OFFSET bufferEntrada
    mov ecx, 10
    call ReadString

    call CadenaAEntero
    cmp eax, -1
    je err_ext_ingresada
    cmp eax, 0
    jl err_ext_ingresada
    cmp eax, 100
    jg err_ext_ingresada

    mov [esi + 38], eax
    jmp exito_registro

err_ext_ingresada:
    MostrarError mensajeErrNum
    jmp pedir_ext_loop

exito_registro:
    inc [total_productos]
    ImprimirTexto mensajeExitoReg
    jmp fin_reg

error_codigo_duplicado:
    MostrarError mensajeDuplicado
    jmp fin_reg

error_codigo_formato:
    MostrarError mensajeErrCodigo
    jmp fin_reg

error_limite:
    ImprimirTexto mensajeLleno
    call Crlf

fin_reg:
    mov esp, ebp
    ret
RegistrarProducto ENDP

; Buscar Producto UI

BuscarProductoUI PROC USES ebp esi
    mov ebp, esp

    mov edx, OFFSET mensajePedirCod
    call WriteString
    LimpiarBuffer
    mov edx, OFFSET bufferEntrada
    mov ecx, TAM_CODIGO
    call ReadString

    call BuscarProductoInterno
    cmp eax, -1
    je no_mostrar

    call Crlf
    ImprimirTexto mensajeEncontrado

    mov edx, OFFSET mensajeTxtCod
    call WriteString
    mov edx, esi
    call WriteString
    call Crlf

    mov edx, OFFSET mensajeTxtNom
    call WriteString
    lea edx, [esi + 8]
    call WriteString
    call Crlf

    mov edx, OFFSET mensajeTxtPre
    call WriteString
    mov eax, [esi + 34]
    call MostrarImporteMXN
    call Crlf

    mov edx, OFFSET mensajeTxtExt
    call WriteString
    mov eax, [esi + 38]
    call MostrarEnteroPropio
    call Crlf
    jmp fin_busqueda

no_mostrar:
    MostrarError mensajeNoEncontrado

fin_busqueda:
    mov esp, ebp
    ret
BuscarProductoUI ENDP

; Recibir Mercancía

RecibirMercancia PROC USES ebp esi ebx
    mov ebp, esp

    mov edx, OFFSET mensajePedirCod
    call WriteString
    LimpiarBuffer
    mov edx, OFFSET bufferEntrada
    mov ecx, TAM_CODIGO
    call ReadString

    call BuscarProductoInterno
    cmp eax, -1
    je rec_no_encontrado

    mov edx, OFFSET mensajePedirCantEnt
    call WriteString
    LimpiarBuffer
    mov edx, OFFSET bufferEntrada
    mov ecx, 10
    call ReadString

    call CadenaAEntero
    cmp eax, -1
    je rec_error_cant
    cmp eax, 0
    jle rec_error_cant

    mov ebx, [esi + 38]
    add ebx, eax
    cmp ebx, 100
    jg rec_error_max

    mov [esi + 38], ebx

    ImprimirTexto mensajeExitoEnt
    jmp fin_rec

rec_error_max:
    MostrarError mensajeErrMaxExt
    jmp fin_rec

rec_error_cant:
    MostrarError mensajeErrNum
    jmp fin_rec

rec_no_encontrado:
    MostrarError mensajeNoEncontrado

fin_rec:
    mov esp, ebp
    ret
RecibirMercancia ENDP

; Vender Producto (Mayoreo 10 o mas)

VenderProducto PROC USES ebp esi ebx ecx
    mov ebp, esp

    mov edx, OFFSET mensajePedirCod
    call WriteString
    LimpiarBuffer
    mov edx, OFFSET bufferEntrada
    mov ecx, TAM_CODIGO
    call ReadString

    call BuscarProductoInterno
    cmp eax, -1
    je venta_no_encontrado

    mov eax, [esi + 38]  
    cmp eax, 0
    jle venta_sin_stock

    mov edx, OFFSET mensajePedirCantVenta
    call WriteString
    LimpiarBuffer
    mov edx, OFFSET bufferEntrada
    mov ecx, 10
    call ReadString

    call CadenaAEntero
    cmp eax, -1
    je venta_sin_stock
    cmp eax, 0
    jle venta_sin_stock
    cmp eax, [esi + 38]
    jg venta_sin_stock

    push eax             

    mov ebx, [esi + 34]  
    mul ebx              

    pop ecx              
    push ecx             

    cmp ecx, 10
    jl sin_descuento

    mov ebx, 90
    mul ebx
    mov ebx, 100
    xor edx, edx
    div ebx              

sin_descuento:
    pop ecx              

    sub [esi + 38], ecx
    add [ingresos_sesion], eax

    call Crlf
    mov edx, OFFSET mensajeVentaExito
    call WriteString
    call MostrarImporteMXN
    call Crlf
    jmp fin_venta

venta_sin_stock:
    MostrarError mensajeSinExistencias
    jmp fin_venta

venta_no_encontrado:
    MostrarError mensajeNoEncontrado

fin_venta:
    mov esp, ebp
    ret
VenderProducto ENDP

; Mostrar Resumen

MostrarResumen PROC USES ebp esi ebx ecx
    mov ebp, esp

    call Crlf
    ImprimirTexto mensajeResumen1

    mov edx, OFFSET mensajeResumenProd
    call WriteString
    mov eax, [total_productos]
    call MostrarEnteroPropio
    call Crlf

    mov esi, OFFSET catalogo
    xor ecx, ecx
    xor ebx, ebx        

ciclo_valor:
    cmp ecx, [total_productos]
    jge fin_ciclo_valor

    mov eax, [esi + 34] 
    mov edx, [esi + 38] 
    push ecx
    mul edx             
    add ebx, eax        
    pop ecx

    add esi, TAM_REGISTRO
    inc ecx
    jmp ciclo_valor

fin_ciclo_valor:
    mov edx, OFFSET mensajeResumenVal
    call WriteString
    mov eax, ebx
    call MostrarImporteMXN
    call Crlf

    mov edx, OFFSET mensajeResumenIng
    call WriteString
    mov eax, [ingresos_sesion]
    call MostrarImporteMXN
    call Crlf

    mov esp, ebp
    ret
MostrarResumen ENDP

; Guardar Archivo 

GuardarArchivo PROC USES eax edx ecx
    mov edx, OFFSET nombreArchivo
    call CreateOutputFile
    mov fileHandle, eax
    cmp eax, INVALID_HANDLE_VALUE
    je error_archivo

    ; Escribir toda la estructura de datos junta (total_productos + ingresos + catálogo)
    mov edx, OFFSET total_productos
    mov ecx, 8 + (TAM_REGISTRO * MAX_PRODUCTOS)
    call WriteToFile

    mov eax, fileHandle
    call CloseFile

    ImprimirTexto mensajeGuardarExito
    jmp fin_guardar

error_archivo:
    MostrarError mensajeErrorArchivo

fin_guardar:
    ret
GuardarArchivo ENDP

; Cargar Archivo

CargarArchivo PROC USES eax edx ecx
    mov edx, OFFSET nombreArchivo
    call OpenInputFile
    mov fileHandle, eax
    cmp eax, INVALID_HANDLE_VALUE
    je error_archivo_carga

    ; Leer toda la estructura de datos junta
    mov edx, OFFSET total_productos
    mov ecx, 8 + (TAM_REGISTRO * MAX_PRODUCTOS)
    call ReadFromFile

    mov eax, fileHandle
    call CloseFile

    ImprimirTexto mensajeCargarExito
    jmp fin_carga

error_archivo_carga:
    MostrarError mensajeErrorArchivo

fin_carga:
    ret
CargarArchivo ENDP

END main