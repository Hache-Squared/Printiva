namespace ManejoPresupuestos.Models
{
    public class UsuarioListaVm
    {
        public int Id { get; set; }
        public string? Nombre { get; set; }
        public string Email { get; set; } = "";
        public bool EstaActivo { get; set; }
        public bool EsAdmin { get; set; }
        public string? Permisos { get; set; } // CSV desde SQL

        public List<string> PermisosList =>
            string.IsNullOrWhiteSpace(Permisos)
                ? new List<string>()
                : Permisos.Split(',').Select(x => x.Trim()).Where(x => x.Length > 0).ToList();
    }

    public class PermisoItemVm
    {
        public string Key { get; set; } = "";
        public string Label { get; set; } = "";
        public bool Selected { get; set; }
    }

    public class UsuarioFormVm
    {
        public int Id { get; set; } // 0 => create
        public string Nombre { get; set; } = "";
        public string Email { get; set; } = "";
        public string? Password { get; set; } // create requerido, edit opcional

        public bool EsAdmin { get; set; }
        public List<string> PermisosSeleccionados { get; set; } = new();

        // para render
        public List<PermisoItemVm> PermisosDisponibles { get; set; } = new();
        public bool EsEdicion => Id > 0;
    }

    public class SpResultVm
    {
        public string Result { get; set; } = "";
        public string Message { get; set; } = "";
        public int ElementoId { get; set; }
    }
}