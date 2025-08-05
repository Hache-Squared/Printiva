using AutoMapper;
using DocumentFormat.OpenXml.EMMA;
using ManejoPresupuestos.Models;
using ManejoPresupuestos.Servicios;
using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Mvc.Rendering;
using Newtonsoft.Json;
using Newtonsoft.Json.Serialization;
using System.Reflection;

namespace ManejoPresupuestos.Controllers
{
    public class RecetasController : Controller
    {
        private readonly IServicioUsuarios servicioUsuarios;
        private readonly IRepositorioProductos repositorioProductos;
        private readonly IRepositorioProductoCategorias repositorioProductoCategorias;
        private readonly IRepositorioRecetas repositorioRecetas;
        private readonly IMapper mapper;

        public RecetasController(
            IServicioUsuarios servicioUsuarios,
            IMapper mapper,
            IRepositorioProductos repositorioProductos,
            IRepositorioProductoCategorias repositorioProductoCategorias,
            IRepositorioRecetas repositorioRecetas
        )
        {
            this.servicioUsuarios = servicioUsuarios;
            this.mapper = mapper;
            this.repositorioProductos = repositorioProductos;
            this.repositorioProductoCategorias = repositorioProductoCategorias;
            this.repositorioRecetas = repositorioRecetas;
        }

        [HttpGet]
        public async Task<IActionResult> Index()
        {
            var usuarioId = servicioUsuarios.ObtenerUsuarioId();
            var param = new ParametroObtenerRecetas()
            {
                ElementoObtenerId = 0,
                LoginId = usuarioId
            };
            var recetas = await repositorioRecetas.ObtenerTodos(param);
            return View(recetas);
        }

        [HttpGet]
        public async Task<IActionResult> RecetaEditor()
        {
            var usuarioId = servicioUsuarios.ObtenerUsuarioId();
            var param = new ParametroObtenerInventariosParaReceta()
            {
                ElementoObtenerId = 0,
                LoginId = usuarioId
            };

            var inventariosReceta = await repositorioRecetas.ObtenerInventariosReceta(param);

            return View(inventariosReceta);
        }

        [HttpPost]
        public async Task<IActionResult> RecetaEditorGuardar([FromBody] CrearRecetaViewModel modelo)
        {
            var usuarioId = servicioUsuarios.ObtenerUsuarioId();

            var param = new ParametroCrearReceta()
            {
                LoginId = usuarioId,
                Nombre = modelo.Nombre,
                ProductoId = modelo.ProductoId,
                Tiempo = modelo.Tiempo
            };
            var crearReceta = await repositorioRecetas.CrearReceta(param);
            if(crearReceta.result != ResultProcedureType.SUCCESS)
            {
                return Json(new
                {
                    result = "fail",
                    message = "Receta no creada: " + crearReceta.message
                });
            }
            var json = JsonConvert.SerializeObject(modelo.Inventarios, new JsonSerializerSettings
            {
                ContractResolver = new DefaultContractResolver(), // Respeta las mayúsculas
                Formatting = Formatting.None
            });
            var paramRelation = new ParametroCrearRelacionRecetaInventario()
            {
                LoginId = usuarioId,
                RecetaId = crearReceta.elementoId,
                Json = json
            };
            var crearRecetaRelacion = await repositorioRecetas.CrearRelacionRecetaInventario(paramRelation);
            if (crearRecetaRelacion.result != ResultProcedureType.SUCCESS)
            {
                return Json(new
                {
                    result = "fail",
                    message = "Receta no creada: " + crearRecetaRelacion.message 
                });
            }


            return Json(new {
                result = "success",
                message = "Receta creada con exito"
            });
        }

    }
}
