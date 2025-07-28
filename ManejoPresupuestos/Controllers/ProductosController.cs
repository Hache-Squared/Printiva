using AutoMapper;
using ManejoPresupuestos.Models;
using ManejoPresupuestos.Servicios;
using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Mvc.Rendering;
using System.Reflection;

namespace ManejoPresupuestos.Controllers
{
    public class ProductosController: Controller
    {
        private readonly IServicioUsuarios servicioUsuarios;
        private readonly IMapper mapper;

        public ProductosController(
            IServicioUsuarios servicioUsuarios,
            IMapper mapper
        )
        {
            this.servicioUsuarios = servicioUsuarios;
            this.mapper = mapper;
        }

        [HttpGet]
        public async Task<IActionResult> RecetaEditor()
        {
            var usuarioId = servicioUsuarios.ObtenerUsuarioId();

            return View();
        }

        [HttpPost]
        public async Task<IActionResult> RecetaEditorGuardar()
        {
            var usuarioId = servicioUsuarios.ObtenerUsuarioId();

            return RedirectToAction("RecetaEditor");
        }

    }
}
