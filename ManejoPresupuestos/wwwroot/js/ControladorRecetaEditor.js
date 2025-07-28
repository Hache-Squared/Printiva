
var ControladorRecetaEditor = {
    listItemsInventariosDisponibles: [],
    listItemsInventariosParaReceta: [],
    inicializarListas: function (listaInventariosDisponibles = [], listInventariosParaReceta = []) {
        this.listItemsInventariosDisponibles = listaInventariosDisponibles;
        let elementosARenderizarInventariosDisponibles = ControladorRecetaEditor.listItemsInventariosDisponibles?.map(x => {
            return ControladorRecetaEditor.RenderItemInventarioDisponible(x)
        })

        $("#left").html(elementosARenderizarInventariosDisponibles);

        this.listItemsInventariosParaReceta = listInventariosParaReceta;
        let elementosARenderizarParaReceta = ControladorRecetaEditor.listItemsInventariosParaReceta?.map(x => {
            return ControladorRecetaEditor.RenderItemInventarioParaReceta(x)
        })

        $("#right").html(elementosARenderizarParaReceta);
    },
    refrescarListas: function () {
        let elementosARenderizarInventariosDisponibles = ControladorRecetaEditor.listItemsInventariosDisponibles?.map(x => {
            return ControladorRecetaEditor.RenderItemInventarioDisponible(x)
        })

        $("#left").html(elementosARenderizarInventariosDisponibles);

        let elementosARenderizarParaReceta = ControladorRecetaEditor.listItemsInventariosParaReceta?.map(x => {
            return ControladorRecetaEditor.RenderItemInventarioParaReceta(x)
        })

        $("#right").html(elementosARenderizarParaReceta);

        ControladorRecetaEditor.inicializarRecetaEditor();
    },
    inicializarRecetaEditor: function () {
        let valoresEjemplo = [];
        let items = document.getElementsByClassName("item-list-drag")
        let rightBox = document.getElementById("right")
        let leftBox = document.getElementById("left")


        for (item of items) {
            item.addEventListener("dragstart", function (e) {
                let selected = e.target;
                let data = $(this).data("payload")
                
                rightBox.addEventListener("dragover", function (e) {
                    e.preventDefault();
                })
                rightBox.addEventListener("drop", function (e) {
                    if (selected !== null) {

                        let index = ControladorRecetaEditor.listItemsInventariosDisponibles.findIndex(x => x.InventarioId === data.InventarioId)
                        if (index !== -1) {
                            ControladorRecetaEditor.listItemsInventariosParaReceta.push(data)
                            ControladorRecetaEditor.listItemsInventariosDisponibles.splice(index, 1);
                        }
                    }
                    selected = null;
                    ControladorRecetaEditor.refrescarListas();
                })

                leftBox.addEventListener("dragover", function (e) {
                    e.preventDefault();
                })
                leftBox.addEventListener("drop", function (e) {
                    
                    if (selected !== null) {
                        
                        let index = ControladorRecetaEditor.listItemsInventariosParaReceta.findIndex(x => x.InventarioId === data.InventarioId)
                        if (index !== -1) {
                            ControladorRecetaEditor.listItemsInventariosDisponibles.push(data)
                            ControladorRecetaEditor.listItemsInventariosParaReceta.splice(index, 1);
                        }
                    }
                    selected = null;
                    ControladorRecetaEditor.refrescarListas();
                })


            })
        }
    },
    RenderItemInventarioDisponible: function (item) {

        return `
            <div data-payload='${JSON.stringify(item)}' draggable="true" class="item-list-drag container my-4 d-flex justify-content-center">
                <div class="w-90 p-4 rounded-3 shadow border bg-light text-black" style="width: 90%;">
                    <div class="row mb-1">
                        <div class="col-sm-6 fw-bold">Marca:</div>
                        <div class="col-sm-6">${item?.InventarioMarca}</div>
                    </div>
                    <div class="row mb-1">
                        <div class="col-sm-6 fw-bold">Nombre Material:</div>
                        <div class="col-sm-6">${item?.InventarioNombre}</div>
                    </div>
                    <div class="row mb-1">
                        <div class="col-sm-6 fw-bold">Color:</div>
                        <div class="col-sm-6">${item?.InventarioColor}</div>
                    </div>
                    
                    <div class="row mb-1">
                        <div class="col-sm-6 fw-bold">Unidad:</div>
                        <div class="col-sm-6">${item?.InventarioUnidad}</div>
                    </div>
                </div>
            </div>
        `;
    },
    RenderItemInventarioParaReceta: function (item) {
        return `
            <div data-payload='${JSON.stringify(item)}' draggable="true" class="item-list-drag container my-4 d-flex justify-content-center">
                <div class="w-90 p-4 rounded-3 shadow border bg-light text-black" style="width: 90%;">
                    <div class="row mb-1">
                        <div class="col-sm-6 fw-bold">Marca:</div>
                        <div class="col-sm-6">${item?.InventarioMarca}</div>
                    </div>
                    <div class="row mb-1">
                        <div class="col-sm-6 fw-bold">Nombre Material:</div>
                        <div class="col-sm-6">${item?.InventarioNombre}</div>
                    </div>
                    <div class="row mb-1">
                        <div class="col-sm-6 fw-bold">Color:</div>
                        <div class="col-sm-6">${item?.InventarioColor}</div>
                    </div>
                    <div class="row mb-1">
                        <div class="col-sm-6 fw-bold">¿Cantidad de material a usar (${item?.InventarioUnidad}) ?: </div>
                        <div class="col-sm-6">
                            <input class="form-control" type="number" min="0"/>
                        </div>
                    </div>
                </div>
            </div>
        `;
    }

}

