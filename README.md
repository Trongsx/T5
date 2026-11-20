# T5 — Do-file automatizado
### Módulo IV · Semana 13 · **Tarea calificada — 13 % de la nota final**
#### Fundamentos de Programación para Análisis Económico · UdeC-EAN

## Qué se automatizó

El script `scripts/tarea_t5.do` transforma el análisis manual en un flujo reproducible y parametrizado:

Todos los parámetros editables (archivo de datos, variable dependiente, listas de variables numéricas, controles, grupos y umbral de ingreso) se definen al inicio mediante `local` y `global`, evitando repetir valores en el cuerpo del código.
Se reemplazaron los comandos repetidos por un `foreach` sobre la lista de variables numéricas  y un `forvalues` con `r(N)` para contar personas por tramos de educación.
Se definió el programa `descriptivos_grupo` con argumentos (`` `1' `` para el grupo y `` `2' `` para la variable dependiente), llamado desde un `foreach` para generar frecuencias y estadísticas por `sector`, `region` y `genero`.
Se utilizó `tempvar` para cálculos auxiliares sin alterar la base y se filtró explícitamente con `!missing()` al aplicar el umbral de ingreso.
Se estimaron y compararon dos modelos con `estimates store` y `estimates table`. Además, se automatizó una regresión por sector con `levelsof` + `foreach`, guardando los resultados en una matriz y exportándolos directamente a Excel con `putexcel`.

## Qué editar para reutilizar el do-file con otros datos

Para adaptar el script a otra base de datos con una estructura similar, solo es necesario modificar el **bloque de parámetros** al inicio de `scripts/tarea_t5.do`:

1. `local datos`: cambiar la ruta hacia el nuevo archivo `.csv`.
2. `local depvar`, `local numericas`, `local controles` y `local grupos`: actualizar los nombres de las variables según la nueva base.
3. `global umbral`: ajustar el valor de corte para el conteo de ingresos.


## Declaración de autoría y uso de IA

```markdown
## Declaración de autoría y uso de IA
- Herramienta utilizada: Gemini (3.1 Pro)
- Para qué la usé: Principalmente para comprar y recordar comandos y variables que hemos utilizado en el curso, además de pulir la redacción de la interpretación para poder ajustar el texto necesario.
- Qué hice yo: Armé y ejecuté el do.file completo, realice las pruebas de parametrización cambiando `global umbral` (de 500.000 a 600.000 y de vuelta), verifiqué los outputs en el `.log` y en el archivo Excel generado, y redacté la interpretación final de los resultados.
- Verificación: confirmo que entiendo y puedo explicar todo lo que entrego.
```