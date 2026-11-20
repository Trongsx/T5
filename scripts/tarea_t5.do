* ============================================================
* T5 — Do-file automatizado
* Autor: [Tomás Troncoso]      Fecha: [2026-11-19]
* Módulo IV · Semana 13 · **Tarea calificada — 13 % de la nota final**
* Fundamentos de Programación para Análisis Económico · UdeC-EAN
* ============================================================

* Cambio de directorio al personal
cd "C:\Users\anton\Desktop\U\Semestre 8\Fundamentos de Programacion\Tareas\T5"

* Confirmar directorio
pwd

* Confirmar que los datos se encuentra en el directorio
confirm file "data/raw/casen_reducido.csv"

* ============================================================
* 1. Encabezado con macros de configuración
* ============================================================

version 14
clear all
set more off
capture mkdir "output"
capture log close
log using "output/tarea_t5.log", replace text

* --- Parámetros (lo único que se edita) ---

local datos     "data/raw/casen_reducido.csv" //local: archivo específico de este do.file.
local depvar    "ingreso" // local: variable dependiente propia de este análisis.
local numericas "ingreso educ edad experiencia" // local: lista de variables usada solo en el loop descriptivo.
local controles "educ experiencia" // local: controles exclusivos de los modelos de este do.file.
local grupos    "sector region genero" // local: categorías de desagregación que solo viven en este reporte.
global umbral   = 500000 // global: Umbral de ingreso de referencia que podría reutilizarse en otros do.files.

* Verificar con global umbral = 600000 


* ============================================================
* 2. Carga y prepara los datos
* ============================================================

import delimited "`datos'", clear varnames(1) encoding("utf-8")
generate experiencia = max(edad - educ - 6, 0)

label variable experiencia "Experiencia potencial (años)"

generate mujer = (genero == "F")
label variable mujer "Mujer (1 = sí)"
label define mujer_lbl 0 "Hombre" 1 "Mujer"
label values mujer mujer_lbl

* ============================================================
* 3. Un `foreach` sobre una lista de variables
* ============================================================

foreach v of local numericas {
    summarize `v', detail
}

* ============================================================
* 4. Un `forvalues` con un rango
* ============================================================

forvalues t = 4(4)16 {
    quietly count if educ >= `t' & educ < `t' + 4
    display "Educación de `t' a " `t' + 3 " años: " r(N) " personas"
}

* ============================================================
* 5. Un `program` reutilizable con argumentos
* ============================================================

capture program drop descriptivos_grupo
program define descriptivos_grupo
    display _newline "=== Descriptivos de `2' y educ por `1' ==="
    tabulate `1'
    tabstat `2' educ, by(`1') statistics(mean sd n)
end

foreach g of local grupos {
    descriptivos_grupo `g' `depvar'
}

* ============================================================
* 6. Usa `tempvar` al menos una vez
* ============================================================

tempvar ing_miles
generate `ing_miles' = `depvar' / 1000
summarize `ing_miles'

* Comentario:
* tempvar crea un nombre interno único y se borra sola al terminar el do.file.
* Es más seguro que (generate + drop) porque nunca pisa una variable real de la base
* ni deja columnas basura si el código se interrumpe antes del drop.

* ============================================================
* 7. Maneja los missing correctamente
* ============================================================

count if `depvar'  > $umbral & !missing(`depvar')

* Comentario:
* En Stata, los NAs o (.) son tratados como mayores que cualquier número.
* Sin "& !missing(`depvar')", las 5 personas sin ingreso se contarían erróneamente
* como si ganaran más de $umbral, daría 46 en vez de 41 con umbral = 500000.


* ============================================================
* 8. Modelos guardados y comparados (S13)
* ============================================================

quietly regress `depvar' `controles'
estimates store m1

quietly regress `depvar' `controles' i.mujer
estimates store m2

estimates table m1 m2, b(%9.0f) se stats(N r2) stfmt(%5.3f)

display "Coeficiente de educación (m2): $" %9.0fc _b[educ] " (ee = " %9.0fc _se[educ] ")"

* ============================================================
* 9. Una regresión por grupo, guardada en una matriz y exportada
* ============================================================

levelsof sector, local(sectores)
local k : word count `sectores'          // cuántos sectores hay
matrix R = J(`k', 3, .)                  // k filas, 3 columnas, todo missing

local i = 1                               // contador de fila
foreach s of local sectores {
    quietly regress `depvar' educ if sector == "`s'"
    matrix R[`i', 1] = _b[educ]           // fila i, columna 1: el coeficiente
    matrix R[`i', 2] = _se[educ]          // columna 2: su error estándar
    matrix R[`i', 3] = e(N)               // columna 3: cuántas personas
    local i = `i' + 1                     // pasar a la fila siguiente
}

matrix colnames R = beta_educ ee n
matrix rownames R = `sectores'
matrix list R, format(%9.0f)

* Exportar matriz a Excel con los nombres de los sectores en la columna A
putexcel set "output/tarea_t5_por_sector.xlsx", replace
putexcel A1 = ("Sector") B1 = ("Beta educ") C1 = ("Error est.") D1 = ("n")
putexcel B2 = matrix(R)

local fila = 2
foreach s of local sectores {
    putexcel A`fila' = ("`s'")
    local fila = `fila' + 1
}

* ============================================================
* 10. Cierra el log e interpreta
* ============================================================

log close

* Interpretacion:
* Comparando m1 y m2, el hecho de incluir la variable mujer apenas mueve el coeficiente
* de educación, cada año extra se asocia con $42.019 más de ingreso mensual
* en m1 y $42.246 en m2, manteniendo fija la experiencia y el género en m2, 
* mientras que el R2 sube levemente de 0,458 a 0,475. Por otro lado, las 
* regresiones por sector son poco precisas porque tienen muy pocas personas 
* (Construcción: 5, Comercio: 6, Educación: 7, Industria: 9, Agricultura: 13 
* y Servicios: 15), lo que aumemta los errores estándar. Como limitación, con 
* solo 55 datos válidos y sin controlar por calidad educativa, esto es puramente descriptivo y no muestra causalidad.
