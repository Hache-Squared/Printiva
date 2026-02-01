var ControladorRecetaEditor = {
    listItemsInventariosDisponibles: [],
    listItemsInventariosParaReceta: [],

    inicializarListener: function (url) {
        $("#btn-guardar-receta").click(async function () {
            let resultadoReceta = ControladorRecetaEditor.GetInventarioParaReceta();
            if (!resultadoReceta?.esValido) {
                alert(resultadoReceta?.mensaje);
                return;
            }

            let nombre = $("#nombre-receta").val();

            // Tiempo impresión (min)
            let tiempoImpresionRaw = $("#tiempo-receta").val();
            let tiempoImpresionMin = parseInt(tiempoImpresionRaw, 10);

            // Tiempo post (min)
            let tiempoPostRaw = $("#tiempo-post-receta").val();
            let tiempoPostMin = parseInt(tiempoPostRaw, 10);

            if (nombre?.trim() === "") {
                alert("Nombre para receta es requerido");
                return;
            }

            if (isNaN(tiempoImpresionMin) || tiempoImpresionMin <= 0) {
                alert("Tiempo de impresión debe ser un número mayor a 0 (minutos).");
                return;
            }

            if (isNaN(tiempoPostMin) || tiempoPostMin < 0) {
                alert("Tiempo de post-proceso debe ser un número válido (0 o mayor).");
                return;
            }

            let inventarios = resultadoReceta?.resultados ?? [];
            let inventariosAEnviar = inventarios?.map(x => {
                return {
                    InventarioId: x?.InventarioId,
                    Cantidad: x?.cantidadRequerida
                }
            });

            let recetaId = parseInt($("#receta-id").val()) || 0;

            const form = {
                RecetaId: recetaId,
                Nombre: nombre,

                // legacy (por si algo viejo lo usa aún)
                Tiempo: tiempoImpresionMin.toString(),

                // nuevos
                TiempoImpresionMin: tiempoImpresionMin,
                TiempoPostMin: tiempoPostMin,

                ProductoId: 0,
                Inventarios: inventariosAEnviar
            };

            const respuesta = await fetch(url, {
                method: "POST",
                body: JSON.stringify(form),
                headers: { 'Content-type': 'application/json' }
            });

            const json = await respuesta.json();
            if (json?.result !== "success") {
                alert(json?.message);
                return;
            }

            alert(json?.message);
            ControladorRecetaEditor.LimpiarLocalStorage();
            window.location.href = '/Recetas';
        });
    },

    inicializarListas: function (listaInventariosDisponibles = [], listInventariosParaReceta = []) {
        if (!this.CargarDesdeLocalStorage()) {
            this.listItemsInventariosDisponibles = listaInventariosDisponibles;
            this.listItemsInventariosParaReceta = listInventariosParaReceta;
        }
        this.refrescarListas();
    },

    refrescarListas: function () {
        const elementosDisponibles = this.listItemsInventariosDisponibles.map(x => this.RenderItemInventarioDisponible(x));
        $("#left").html(elementosDisponibles);

        const elementosParaReceta = this.listItemsInventariosParaReceta.map(x => this.RenderItemInventarioParaReceta(x));
        $("#right").html(elementosParaReceta);

        this.inicializarRecetaEditor();
        this.GuardarEnLocalStorage();

        $(".control-value-quantity").off("input").on("input", function () {
            const payload = JSON.parse($(this).closest(".item-for-inventory").attr("data-payload"));
            const item = ControladorRecetaEditor.listItemsInventariosParaReceta.find(x => x.InventarioId === payload.InventarioId);
            if (item) {
                item.cantidadRequerida = parseFloat($(this).val()) || 0;
                ControladorRecetaEditor.GuardarEnLocalStorage();
            }
        });
    },

    inicializarRecetaEditor: function () {
        let items = document.getElementsByClassName("item-list-drag");
        let rightBox = document.getElementById("right");
        let leftBox = document.getElementById("left");

        for (let item of items) {
            item.addEventListener("dragstart", function (e) {
                let selected = e.target;
                let data = $(this).data("payload");

                rightBox.addEventListener("dragover", function (e) { e.preventDefault(); });
                rightBox.addEventListener("drop", function (e) {
                    if (selected !== null) {
                        let index = ControladorRecetaEditor.listItemsInventariosDisponibles.findIndex(x => x.InventarioId === data.InventarioId);
                        if (index !== -1) {
                            ControladorRecetaEditor.listItemsInventariosParaReceta.push(data);
                            ControladorRecetaEditor.listItemsInventariosDisponibles.splice(index, 1);
                        }
                    }
                    selected = null;
                    ControladorRecetaEditor.refrescarListas();
                });

                leftBox.addEventListener("dragover", function (e) { e.preventDefault(); });
                leftBox.addEventListener("drop", function (e) {
                    if (selected !== null) {
                        let index = ControladorRecetaEditor.listItemsInventariosParaReceta.findIndex(x => x.InventarioId === data.InventarioId);
                        if (index !== -1) {
                            ControladorRecetaEditor.listItemsInventariosDisponibles.push(data);
                            ControladorRecetaEditor.listItemsInventariosParaReceta.splice(index, 1);
                        }
                    }
                    selected = null;
                    ControladorRecetaEditor.refrescarListas();
                });
            });
        }
    },

    RenderItemInventarioDisponible: function (item) {
        return `
            <div data-payload='${JSON.stringify(item)}' draggable="true" class="item-list-drag container my-4 d-flex justify-content-center">
                <div class="w-90 p-4 rounded-3 shadow border bg-light text-black" style="width: 90%;">
                    <div class="row mb-1"><div class="col-sm-6 fw-bold">Marca:</div><div class="col-sm-6">${item?.InventarioMarca}</div></div>
                    <div class="row mb-1"><div class="col-sm-6 fw-bold">Nombre Material:</div><div class="col-sm-6">${item?.InventarioNombre}</div></div>
                    <div class="row mb-1"><div class="col-sm-6 fw-bold">Color:</div><div class="col-sm-6">${item?.InventarioColor}</div></div>
                    <div class="row mb-1"><div class="col-sm-6 fw-bold">Unidad:</div><div class="col-sm-6">${item?.InventarioUnidad}</div></div>
                </div>
            </div>
        `;
    },

    RenderItemInventarioParaReceta: function (item) {
        const cantidad = item?.cantidadRequerida ?? "";
        return `
            <div data-payload='${JSON.stringify(item)}' draggable="true" class="item-list-drag container my-4 d-flex justify-content-center item-for-inventory">
                <div class="w-90 p-4 rounded-3 shadow border bg-light text-black" style="width: 90%;">
                    <div class="row mb-1"><div class="col-sm-6 fw-bold">Marca:</div><div class="col-sm-6">${item?.InventarioMarca}</div></div>
                    <div class="row mb-1"><div class="col-sm-6 fw-bold">Nombre Material:</div><div class="col-sm-6">${item?.InventarioNombre}</div></div>
                    <div class="row mb-1"><div class="col-sm-6 fw-bold">Color:</div><div class="col-sm-6">${item?.InventarioColor}</div></div>
                    <div class="row mb-1">
                        <div class="col-sm-6 fw-bold">¿Cantidad de material a usar (${item?.InventarioUnidad})?: </div>
                        <div class="col-sm-6">
                            <input class="form-control control-value-quantity" type="number" min="0" value="${cantidad}" />
                        </div>
                    </div>
                </div>
            </div>
        `;
    },

    GetInventarioParaReceta: function () {
        const elementos = document.querySelectorAll('.item-for-inventory');
        const resultado = [];
        const objeto = { resultados: [], esValido: true, mensaje: "" };
        let error = false;
        let msg = "";

        elementos.forEach(elemento => {
            const rawData = elemento.getAttribute('data-payload');
            const item = JSON.parse(rawData);
            const inputCantidad = elemento.querySelector('.control-value-quantity');
            let cantidad = 0;

            if (this.esNumeroMayorACero(inputCantidad.value)) {
                cantidad = parseFloat(inputCantidad.value);
            } else {
                error = true;
                msg = "La cantidad debe ser un número mayor a cero.";
            }

            item.cantidadRequerida = isNaN(cantidad) ? 0 : cantidad;
            resultado.push(item);
        });

        if (resultado.length === 0) {
            error = true;
            msg = "Relacione al menos un inventario a la receta.";
        }

        objeto.resultados = resultado;
        objeto.esValido = !error;
        objeto.mensaje = msg;
        return objeto;
    },

    esNumeroMayorACero: function (valor) {
        const numero = parseFloat(valor);
        return !isNaN(numero) && numero > 0;
    },

    GuardarEnLocalStorage: function () {
        localStorage.setItem('inventariosDisponibles', JSON.stringify(this.listItemsInventariosDisponibles));
        localStorage.setItem('inventariosParaReceta', JSON.stringify(this.listItemsInventariosParaReceta));
    },

    CargarDesdeLocalStorage: function () {
        const disponibles = localStorage.getItem('inventariosDisponibles');
        const paraReceta = localStorage.getItem('inventariosParaReceta');
        if (disponibles && paraReceta) {
            this.listItemsInventariosDisponibles = JSON.parse(disponibles);
            this.listItemsInventariosParaReceta = JSON.parse(paraReceta);
            return true;
        }
        return false;
    },

    LimpiarLocalStorage: function () {
        localStorage.removeItem('inventariosDisponibles');
        localStorage.removeItem('inventariosParaReceta');
    }
};