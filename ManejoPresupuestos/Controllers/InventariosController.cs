using AutoMapper;
using ManejoPresupuestos.Models;
using ManejoPresupuestos.Servicios;
using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Mvc.Rendering;

namespace ManejoPresupuestos.Controllers
{
    public class InventariosController : Controller
    {
        private readonly IServicioUsuarios servicioUsuarios;
        private readonly IRepositorioInventarioMarcas repositorioInventarioMarcas;
        private readonly IRepositorioInventarioTipos repositorioInventarioTipos;
        private readonly IRepositorioInventarioColores repositorioInventarioColores;
        private readonly IRepositorioInventarioNombres repositorioInventarioNombres;
        private readonly IRepositorioInventarioUnidades repositorioInventarioUnidades;
        private readonly IRepositorioInventarios repositorioInventarios;
        private readonly IMapper mapper;

        public InventariosController(
            IServicioUsuarios servicioUsuarios,
            IRepositorioInventarioMarcas repositorioInventarioMarcas, 
            IRepositorioInventarioTipos repositorioInventarioTipos, 
            IRepositorioInventarioColores repositorioInventarioColores,
            IRepositorioInventarioNombres repositorioInventarioNombres,
            IRepositorioInventarioUnidades repositorioInventarioUnidades,
            IRepositorioInventarios repositorioInventarios,
            IMapper mapper
        )
        {
            this.servicioUsuarios = servicioUsuarios;
            this.repositorioInventarioMarcas = repositorioInventarioMarcas;
            this.repositorioInventarioTipos = repositorioInventarioTipos;
            this.repositorioInventarioColores = repositorioInventarioColores;
            this.repositorioInventarioNombres = repositorioInventarioNombres;
            this.repositorioInventarioUnidades = repositorioInventarioUnidades;
            this.repositorioInventarios = repositorioInventarios;
            this.mapper = mapper;
        }

        [HttpGet]
        async public Task<IActionResult> Index()
        {
            var usuarioId = servicioUsuarios.ObtenerUsuarioId();
            var inventarios = await repositorioInventarios.ObtenerTodos(usuarioId);

            return View(inventarios);
        }

        async public Task<IActionResult> Marcas()
        {
            var marcas = await this.repositorioInventarioMarcas.ObtenerTodos();
            return View(marcas);
        }

        async public Task<IActionResult> Tipos()
        {
            var tipos = await this.repositorioInventarioTipos.ObtenerTodos();
            return View(tipos);
        }

        async public Task<IActionResult> Colores()
        {
            var colores = await this.repositorioInventarioColores.ObtenerTodos();
            return View(colores);
        }

        async public Task<IActionResult> Nombres()
        {
            var nombres = await this.repositorioInventarioNombres.ObtenerTodos();
            return View(nombres);
        }

        [HttpGet]
        public async Task<IActionResult> Crear()
        {
            var modelo = new InventarioCreacionViewModel();
            modelo.Marcas = await ObtenerMarcas();
            modelo.Tipos = await ObtenerTipos();
            modelo.Colores = await ObtenerColores();
            modelo.Nombres = await ObtenerNombres();
            modelo.Unidades = await ObtenerUnidades();

            return View(modelo);
        }

        [HttpPost]
        public async Task<IActionResult> Crear(InventarioCreacionViewModel inventario)
        {
            // Validaciones
            var marca = await repositorioInventarioMarcas.ObtenerPorId(inventario.InventarioMarcaId);
            var tipo = await repositorioInventarioTipos.ObtenerPorId(inventario.InventarioTipoId);
            var nombre = await repositorioInventarioNombres.ObtenerPorId(inventario.InventarioNombreId);
            var color = await repositorioInventarioColores.ObtenerPorId(inventario.InventarioColorId);
            var unidad = await repositorioInventarioUnidades.ObtenerPorId(inventario.InventarioUnidadId);

            if (
                marca is null ||
                tipo is null ||
                nombre is null ||
                color is null ||
                unidad is null
            )
            {
                return RedirectToAction("NoEncontrado", "Home");
            }

            if (!ModelState.IsValid)
            {
                inventario.Marcas = await ObtenerMarcas();
                inventario.Tipos = await ObtenerTipos();
                inventario.Colores = await ObtenerColores();
                inventario.Nombres = await ObtenerNombres();
                inventario.Unidades = await ObtenerUnidades();

                return View(inventario);
            }

            await repositorioInventarios.Crear(inventario);
            return RedirectToAction("Index");
        }

        [HttpGet]
        public async Task<IActionResult> Editar(int id)
        {
            var usuarioId = servicioUsuarios.ObtenerUsuarioId();
            var inventario = await repositorioInventarios.ObtenerPorId(usuarioId, id);
            if (inventario is null)
            {
                return RedirectToAction("NoEncontrado", "Home");
            }

            var modelo = mapper.Map<InventarioCreacionViewModel>(inventario);

            modelo.Marcas = await ObtenerMarcas();
            modelo.Tipos = await ObtenerTipos();
            modelo.Colores = await ObtenerColores();
            modelo.Nombres = await ObtenerNombres();
            modelo.Unidades = await ObtenerUnidades();

            return View(modelo);
        }

        [HttpPost]
        public async Task<IActionResult> Editar(InventarioCreacionViewModel inventarioEditar)
        {
            var usuarioId = servicioUsuarios.ObtenerUsuarioId();
            var inventario = await repositorioInventarios.ObtenerPorId(usuarioId, inventarioEditar.InventarioId);
            if (inventario is null)
            {
                return RedirectToAction("NoEncontrado", "Home");
            }

            // Validaciones
            var marca = await repositorioInventarioMarcas.ObtenerPorId(inventarioEditar.InventarioMarcaId);
            var tipo = await repositorioInventarioTipos.ObtenerPorId(inventarioEditar.InventarioTipoId);
            var nombre = await repositorioInventarioNombres.ObtenerPorId(inventarioEditar.InventarioNombreId);
            var color = await repositorioInventarioColores.ObtenerPorId(inventarioEditar.InventarioColorId);
            var unidad = await repositorioInventarioUnidades.ObtenerPorId(inventarioEditar.InventarioUnidadId);

            if (
                marca is null ||
                tipo is null ||
                nombre is null ||
                color is null ||
                unidad is null
            )
            {
                return RedirectToAction("NoEncontrado", "Home");
            }

            if (!ModelState.IsValid)
            {
                return View(inventarioEditar);
            }

            await repositorioInventarios.Actualizar(usuarioId, inventarioEditar);
            return RedirectToAction("Index");
        }

        [HttpGet]
        public async Task<IActionResult> Borrar(int id)
        {
            var usuarioId = servicioUsuarios.ObtenerUsuarioId();
            var inventario = await repositorioInventarios.ObtenerPorId(usuarioId, id);
            if (inventario is null)
            {
                return RedirectToAction("NoEncontrado", "Home");
            }
            return View(inventario);
        }

        [HttpPost]
        public async Task<IActionResult> BorrarInventario(int inventarioId)
        {
            var usuarioId = servicioUsuarios.ObtenerUsuarioId();
            var inventario = await repositorioInventarios.ObtenerPorId(usuarioId, inventarioId);
            if (inventario is null)
            {
                return RedirectToAction("NoEncontrado", "Home");
            }

            await repositorioInventarios.Borrar(usuarioId, inventarioId);

            return RedirectToAction("Index");
        }

        [HttpGet]
        public IActionResult CrearMarca()
        {
            return View(null);
        }

        [HttpPost]
        async public Task<IActionResult> CrearMarca(InventarioMarca marca)
        {
            if (!ModelState.IsValid)
            {
                return View(marca);
            }

            await repositorioInventarioMarcas.Crear(marca);

            return RedirectToAction("Marcas");
        }

        [HttpGet]
        public async Task<IActionResult> EditarMarca(int id)
        {
            var marca = await repositorioInventarioMarcas.ObtenerPorId(id);

            if (marca is null)
            {
                return RedirectToAction("NoEncontrado", "Home");
            }

            return View(marca);
        }

        [HttpPost]
        public async Task<IActionResult> EditarMarca(InventarioMarca marcaEditar)
        {
            if (!ModelState.IsValid)
            {
                return View(marcaEditar);
            }

            var marca = await repositorioInventarioMarcas.ObtenerPorId(marcaEditar.InventarioMarcaId);

            if (marca is null)
            {
                return RedirectToAction("NoEncontrado", "Home");
            }

            var usuarioId = servicioUsuarios.ObtenerUsuarioId();
            await repositorioInventarioMarcas.Actualizar(usuarioId, marcaEditar);

            return RedirectToAction("Marcas");
        }

        [HttpGet]
        public async Task<IActionResult> BorrarMarcaForm(int id)
        {
            var marca = await repositorioInventarioMarcas.ObtenerPorId(id);

            if (marca is null)
            {
                return RedirectToAction("NoEncontrado", "Home");
            }

            return View(marca);
        }

        [HttpPost]
        public async Task<IActionResult> BorrarMarca(int inventarioMarcaId)
        {
            var marca = await repositorioInventarioMarcas.ObtenerPorId(inventarioMarcaId);

            if (marca is null)
            {
                return RedirectToAction("NoEncontrado", "Home");
            }

            var usuarioId = servicioUsuarios.ObtenerUsuarioId();
            await repositorioInventarioMarcas.Borrar(usuarioId, inventarioMarcaId);
            return RedirectToAction("Marcas");
        }

        [HttpGet]
        public IActionResult CrearTipo()
        {
            return View(null);
        }

        [HttpPost]
        async public Task<IActionResult> CrearTipo(InventarioTipo tipo)
        {
            if (!ModelState.IsValid)
            {
                return View(tipo);
            }

            await repositorioInventarioTipos.Crear(tipo);

            return RedirectToAction("Tipos");
        }

        [HttpGet]
        public async Task<IActionResult> EditarTipo(int id)
        {
            var tipo = await repositorioInventarioTipos.ObtenerPorId(id);

            if (tipo is null)
            {
                return RedirectToAction("NoEncontrado", "Home");
            }

            return View(tipo);
        }

        [HttpPost]
        public async Task<IActionResult> EditarTipo(InventarioTipo tipoEditar)
        {
            if (!ModelState.IsValid)
            {
                return View(tipoEditar);
            }

            var tipo = await repositorioInventarioTipos.ObtenerPorId(tipoEditar.InventarioTipoId);

            if (tipo is null)
            {
                return RedirectToAction("NoEncontrado", "Home");
            }

            var usuarioId = servicioUsuarios.ObtenerUsuarioId();
            await repositorioInventarioTipos.Actualizar(usuarioId, tipoEditar);

            return RedirectToAction("Tipos");
        }

        [HttpGet]
        public async Task<IActionResult> BorrarTipoForm(int id)
        {
            var tipo = await repositorioInventarioTipos.ObtenerPorId(id);

            if (tipo is null)
            {
                return RedirectToAction("NoEncontrado", "Home");
            }

            return View(tipo);
        }

        [HttpPost]
        public async Task<IActionResult> BorrarTipo(int inventarioTipoId)
        {
            var tipo = await repositorioInventarioTipos.ObtenerPorId(inventarioTipoId);

            if (tipo is null)
            {
                return RedirectToAction("NoEncontrado", "Home");
            }

            var usuarioId = servicioUsuarios.ObtenerUsuarioId();
            await repositorioInventarioTipos.Borrar(usuarioId, inventarioTipoId);
            return RedirectToAction("Tipos");
        }

        [HttpGet]
        public IActionResult CrearColor()
        {
            return View(null);
        }

        [HttpPost]
        async public Task<IActionResult> CrearColor(InventarioColor color)
        {
            if (!ModelState.IsValid)
            {
                return View(color);
            }

            await repositorioInventarioColores.Crear(color);

            return RedirectToAction("Colores");
        }

        [HttpGet]
        public async Task<IActionResult> EditarColor(int id)
        {
            var color = await repositorioInventarioColores.ObtenerPorId(id);

            if (color is null)
            {
                return RedirectToAction("NoEncontrado", "Home");
            }

            return View(color);
        }

        [HttpPost]
        public async Task<IActionResult> EditarColor(InventarioColor colorEditar)
        {
            if (!ModelState.IsValid)
            {
                return View(colorEditar);
            }

            var color = await repositorioInventarioColores.ObtenerPorId(colorEditar.InventarioColorId);

            if (color is null)
            {
                return RedirectToAction("NoEncontrado", "Home");
            }

            var usuarioId = servicioUsuarios.ObtenerUsuarioId();
            await repositorioInventarioColores.Actualizar(usuarioId, colorEditar);

            return RedirectToAction("Colores");
        }

        [HttpGet]
        public async Task<IActionResult> BorrarColorForm(int id)
        {
            var color = await repositorioInventarioColores.ObtenerPorId(id);

            if (color is null)
            {
                return RedirectToAction("NoEncontrado", "Home");
            }

            return View(color);
        }

        [HttpPost]
        public async Task<IActionResult> BorrarColor(int inventarioColorId)
        {
            var color = await repositorioInventarioColores.ObtenerPorId(inventarioColorId);

            if (color is null)
            {
                return RedirectToAction("NoEncontrado", "Home");
            }

            var usuarioId = servicioUsuarios.ObtenerUsuarioId();
            await repositorioInventarioColores.Borrar(usuarioId, inventarioColorId);
            return RedirectToAction("Colores");
        }

        [HttpGet]
        public IActionResult CrearNombre()
        {
            return View(null);
        }

        [HttpPost]
        async public Task<IActionResult> CrearNombre(InventarioNombre nombreCrear)
        {
            if (!ModelState.IsValid)
            {
                return View(nombreCrear);
            }

            await repositorioInventarioNombres.Crear(nombreCrear);

            return RedirectToAction("Nombres");
        }

        [HttpGet]
        public async Task<IActionResult> EditarNombre(int id)
        {
            var nombre = await repositorioInventarioNombres.ObtenerPorId(id);

            if (nombre is null)
            {
                return RedirectToAction("NoEncontrado", "Home");
            }

            return View(nombre);
        }

        [HttpPost]
        public async Task<IActionResult> EditarNombre(InventarioNombre nombreEditar)
        {
            if (!ModelState.IsValid)
            {
                return View(nombreEditar);
            }

            var nombre = await repositorioInventarioNombres.ObtenerPorId(nombreEditar.InventarioNombreId);

            if (nombre is null)
            {
                return RedirectToAction("NoEncontrado", "Home");
            }

            var usuarioId = servicioUsuarios.ObtenerUsuarioId();
            await repositorioInventarioNombres.Actualizar(usuarioId, nombreEditar);

            return RedirectToAction("Nombres");
        }

        [HttpGet]
        public async Task<IActionResult> BorrarNombreForm(int id)
        {
            var nombre = await repositorioInventarioNombres.ObtenerPorId(id);

            if (nombre is null)
            {
                return RedirectToAction("NoEncontrado", "Home");
            }

            return View(nombre);
        }

        [HttpPost]
        public async Task<IActionResult> BorrarNombre(int inventarioNombreId)
        {
            var nombre = await repositorioInventarioNombres.ObtenerPorId(inventarioNombreId);

            if (nombre is null)
            {
                return RedirectToAction("NoEncontrado", "Home");
            }

            var usuarioId = servicioUsuarios.ObtenerUsuarioId();
            await repositorioInventarioNombres.Borrar(usuarioId, inventarioNombreId);
            return RedirectToAction("Nombres");
        }

        private async Task<IEnumerable<SelectListItem>> ObtenerMarcas()
        {
            var marcas = await repositorioInventarioMarcas.ObtenerTodos();

            return marcas.Select(x => new SelectListItem(x.Nombre, x.InventarioMarcaId.ToString()));
        }

        private async Task<IEnumerable<SelectListItem>> ObtenerTipos()
        {
            var tipos = await repositorioInventarioTipos.ObtenerTodos();

            return tipos.Select(x => new SelectListItem(x.Nombre, x.InventarioTipoId.ToString()));
        }

        private async Task<IEnumerable<SelectListItem>> ObtenerNombres()
        {
            var nombres = await repositorioInventarioNombres.ObtenerTodos();

            return nombres.Select(x => new SelectListItem(x.Nombre, x.InventarioNombreId.ToString()));
        }

        private async Task<IEnumerable<SelectListItem>> ObtenerColores()
        {
            var colores = await repositorioInventarioColores.ObtenerTodos();

            return colores.Select(x => new SelectListItem(x.Nombre, x.InventarioColorId.ToString()));
        }

        private async Task<IEnumerable<SelectListItem>> ObtenerUnidades()
        {
            var unidades = await repositorioInventarioUnidades.ObtenerTodos();

            return unidades.Select(x => new SelectListItem(x.Nombre, x.InventarioUnidadId.ToString()));
        }
    }
}
