using AutoMapper;
using ManejoPresupuestos.Models;
using ManejoPresupuestos.Servicios;
using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Mvc.Rendering;
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
            var recetas = new List<Receta>();
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
        public async Task<IActionResult> RecetaEditorGuardar()
        {
            var usuarioId = servicioUsuarios.ObtenerUsuarioId();

            return RedirectToAction("RecetaEditor");
        }

    }
}
